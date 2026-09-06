#include "mod_lib.h"

#include "zip.h"

#include <direct.h>
#include <sys/stat.h>
#include <stdlib.h>

//windows macros
#ifdef _WIN32
  #define strdup _strdup
#endif

//typedef
typedef struct tstd_list_t {
  size_t length;
  size_t capacity;
  void** head;
} list;
enum scope_t {
  global,
  local,
};
typedef struct mod_lib_token_window_t {
  size_t start;
  size_t end;
  enum scope_t scope;
} token_window;
typedef struct mod_lib_context_t {
  char* scripts_path;
  FILE* current_script_file;
  char* current_script_path;
  list* current_script_tokens;
} mod_lib_context;

//PARSING
bool preprocess_as_file(mod_lib_context* context, struct zip_t* zip);

list* get_tokens(char* buffer, size_t bufsize);

bool process_tokens(mod_lib_context* context, list* tokens);

bool trim_tokens(list* tokens);

size_t find_closing_token(list* tokens, size_t opening_token); //finds token containing } that corresponds with the first { in said token

//INJECTION
token_window* find_class_window(list* token_list, char* class_name);
token_window* find_function_window(list* token_list, token_window* class_window, char* function_name);
token_window* find_enum_window(list* token_list, token_window* class_window, char* enum_name);
token_window* find_property_window(list* token_list, token_window* class_window, char* property_name);
bool inject_window(list* target_list, size_t target_index, list* source_list, token_window* source_window); //injects source window into target_list at the specified index (will resize target list if neccessary to fit)

//FILE UTILS
const char* get_file_extension(const char* file_name);
bool file_exists(char* filepath);
bool make_path(char* filepath);

list* read_file_as_tokens(FILE** file);

bool write_file_as_tokens(FILE** file, const char* file_path, list* tokens);

//STRING UTILS
char* substring(char* string, int start, int end);
bool token_is_spacing(char* token);

//LIST
bool list_create_sized(struct tstd_list_t* list, size_t capacity);
bool list_create_empty(struct tstd_list_t* list);
bool list_add(struct tstd_list_t* list, void* item);
void* list_pop(struct tstd_list_t* list);
void* list_remove(struct tstd_list_t* list, size_t index);
bool list_insert(struct tstd_list_t* list, void* item, size_t index);
void* list_get(struct tstd_list_t* list, size_t index);
void list_destroy(struct tstd_list_t* list);
bool list_resize(struct tstd_list_t* list, size_t capacity);
bool list_is_empty(struct tstd_list_t* list);

//TOKEN WINDOW
struct mod_lib_token_window_t* token_window_create(size_t start, size_t end);
bool remove_window_from_list(struct mod_lib_token_window_t* window, list* token_list);


//                                     //
//                                     //
//                                     //
//               LIBRARY               //
//                                     //
//                                     //
//                                     //


mod_lib_context* mod_lib_init(const char* script_path) {
  mod_lib_context* context = malloc(sizeof(mod_lib_context));
  
  if(context == NULL) return NULL;

  context->scripts_path = strdup(script_path);
  context->current_script_file = NULL;
  context->current_script_path = NULL;
  context->current_script_tokens = NULL;

  return context;
}

void mod_lib_destroy(mod_lib_context* context) {
  if(context->scripts_path != NULL) { //free scripts path
    free(context->scripts_path);
    context->scripts_path = NULL;
  }
  if(context->current_script_file != NULL) { //close scripts file
    fclose(context->current_script_file);
    context->current_script_file = NULL;
  }
  if(context->current_script_path != NULL) { //free scripts path
    free(context->current_script_path);
    context->current_script_path = NULL;
  }
  if(context->current_script_tokens != NULL) { //free lines list
    list_destroy(context->current_script_tokens);
    context->current_script_tokens = NULL;
  }
  free(context); //free context pointer
}

bool install_mod_zip(mod_lib_context* context, const char* mod_path) {
  if(context->scripts_path == NULL || mod_path == NULL) return false;
  #ifdef mod_lib_debug
    //printf("[LIB-DEBUG] Opening: %s into: %s\n", mod_path, context->scripts_path);
  #endif
  if(zip_extract(mod_path, context->scripts_path, NULL, NULL) == 0) return true;

  return false;
}

bool install_mod_asmod(mod_lib_context* context, const char* mod_path) {
  if(context->scripts_path == NULL || mod_path == NULL) return false;
  #ifdef mod_lib_debug
    //printf("[LIB-DEBUG] Opening: %s into: %s\n", mod_path, context->scripts_path);
  #endif
  struct zip_t* zip = zip_open(mod_path, ZIP_DEFAULT_COMPRESSION_LEVEL, 'r');

  if(zip == NULL) return false;

  int entry_count = zip_entries_total(zip);

  for(int i = 0; i < entry_count; i++) {
    zip_entry_openbyindex(zip, i); 
    {
      #ifdef mod_lib_debug
        //printf("[LIB-DEBUG] Starting Preprocessing: %s\n", zip_entry_name(zip));
      #endif
      if(!preprocess_as_file(context, zip)) {
        #ifdef mod_lib_debug
          printf("[LIB-DEBUG] Preprocessing Failed: %s\n", zip_entry_name(zip));
        #endif
        zip_entry_close(zip);
        zip_close(zip);
        return false;
      }
    }
    zip_entry_close(zip);
  }
  zip_close(zip);

  return true;
}


//                                     //
//                                     //
//                                     //
//               PARSING               //
//                                     //
//                                     //
//                                     //


bool preprocess_as_file(mod_lib_context* context, struct zip_t* zip) {
  if(zip == NULL) return false;

  if(!zip_entry_isdir(zip) && strcmp(get_file_extension(zip_entry_name(zip)), ".as") == 0) { //not directory and is .as
    //open correspoding scripts file
    if(context->current_script_file != NULL) { //close scripts file
      fclose(context->current_script_file);
      context->current_script_file = NULL;
    }
    if(context->current_script_tokens != NULL) { //free lines list
      list_destroy(context->current_script_tokens);
      context->current_script_tokens = NULL;
    }
    if(context->current_script_path != NULL) {
      free(context->current_script_path);
      context->current_script_path = NULL;
    }

    const char* file_path = zip_entry_name(zip);
    size_t script_file_length = (strlen(context->scripts_path) + strlen(file_path) + 2);
    context->current_script_path = malloc(script_file_length);

    if(context->current_script_path == NULL) return false;

    context->current_script_path[4] = '\0';
    if(strcpy_s(context->current_script_path, script_file_length, context->scripts_path) != 0) return false;
    if(strcat_s(context->current_script_path, script_file_length, file_path) != 0) return false;

    context->current_script_tokens = malloc(sizeof(list));
    if(context->current_script_tokens == NULL) return false;
    list_create_empty(context->current_script_tokens);

    //read zip entry as tokens for the parser
    void* buffer = NULL;
    size_t bufsize;

    if(zip_entry_read(zip, &buffer, &bufsize) < 0) return false;

    context->current_script_tokens = get_tokens((char*) buffer, bufsize);
    if(context->current_script_tokens == NULL) {
      free(buffer);
      #ifdef mod_lib_debug
        puts("[LIB-DEBUG] failed to get tokens");
      #endif
      return false;
    }

    if(!process_tokens(context, context->current_script_tokens)) {
      list_destroy(context->current_script_tokens);
      context->current_script_tokens = NULL;
      free(buffer);
      #ifdef mod_lib_debug
        puts("[LIB-DEBUG] failed to process tokens");
      #endif
      return false;
    }

    if(!trim_tokens(context->current_script_tokens)) return false;
    if(context->current_script_tokens->length > 0) { //only write to file if there are tokens stored
      if(!file_exists(context->current_script_path)) {
        if(!make_path(context->current_script_path)) return false;
      }

      if(!write_file_as_tokens(&context->current_script_file, context->current_script_path, context->current_script_tokens)) {
        list_destroy(context->current_script_tokens);
        context->current_script_tokens = NULL;
        free(buffer);
        #ifdef mod_lib_debug
          printf("[LIB-DEBUG] failed to write file: %s\n", context->current_script_path);
        #endif
        return false;
      }
    }

    list_destroy(context->current_script_tokens);
    context->current_script_tokens = NULL;
    free(buffer);
  }

  return true;
}

list* get_tokens(char* buffer, size_t bufsize) {
  size_t token_capacity = 128;
  size_t idx = 0;
  size_t token_char_idx = 0;

  list* tokens = malloc(sizeof(list));

  if(tokens == NULL) {
    return NULL;
  }

  list_create_empty(tokens);

  char* token = malloc(token_capacity);

  if(token == NULL) {
    free(tokens);
    return NULL;
  }

  while(idx < bufsize) {
    if(token_char_idx >= token_capacity - 1) { //resize token if needed
      token_capacity *= 2;
      char* new_token = realloc(token, token_capacity);

      if(new_token == NULL) {
        free(token);
        token = NULL;
        list_destroy(tokens);
        tokens = NULL;
        return NULL;
      }

      token = new_token;
    }

    char c = buffer[idx];

    if(c == '\0') { //skip for null characters
      idx += 1;
      continue;
    }

    if (c == '\r') {
      idx += 1;
      continue;
    }

    if(c == ' ' || c == '\n' || c == '\t') {
      token[token_char_idx] = '\0';

      char* tkn = strdup(token);

      if(tkn == NULL) {
        free(token);
        list_destroy(tokens);
        tokens = NULL;
        return NULL;
      }

      if(tkn[0] != '\0') {
        if(!list_add(tokens, tkn)) {
          free(tkn);
          free(token);
          list_destroy(tokens);
          tokens = NULL;
          return NULL;
        }
      } else {
        free(tkn);
      }

      token_char_idx = 0;
      
      char* spacing = NULL;
      if(c == '\n') { //newline is a token
        spacing = strdup("-NEWLINE");
      } else if(c == '\t') {//tab is a token
        spacing = strdup("-TAB");
      } else if(c == ' ') { //space is a token
        spacing = strdup("-SPACE");
      }

      if(spacing != NULL) {
        if(!list_add(tokens, spacing)) {
          free(spacing);
          free(token);
          list_destroy(tokens);
          tokens = NULL;
          return NULL;
        }
      } else {
        free(spacing);
        free(token);
        list_destroy(tokens);
        tokens = NULL;
        return NULL;
      }
    } else {
      token[token_char_idx] = c;
      token_char_idx += 1;
    }
    idx += 1;
  }

  if(token_char_idx > 0) {
    token[token_char_idx] = '\0';

    char* tkn = strdup(token);

    if(tkn == NULL) {
      free(token);
      list_destroy(tokens);
      tokens = NULL;
      return NULL;
    }

    if(tkn[0] != '\0') {
      if(!list_add(tokens, tkn)) {
        free(tkn);
        free(token);
        list_destroy(tokens);
        tokens = NULL;
        return NULL;
      }
    } else {
      free(tkn);
    }
  }

  free(token);

  return tokens;
}

/*
Valid special tokens:
  OPERATIONS:
    @open
    @import
    @patch
    @add
    @end
    @config
    @// (can have more characters trailing the double slash)

  OPERATION FLAGS:
    function
    property
    enum

  SPACING:
    -NEWLINE
    -SPACE
    -TAB

All other tokens are just appended to the script file
*/
bool process_tokens(mod_lib_context* context, list* tokens) {
  bool status = false;

  FILE* current_mod_file = NULL;
  char* current_mod_dir = NULL;
  list* current_mod_tokens = NULL;

  token_window* class_window = NULL;
  token_window* target_window = NULL;
  char* class_name = NULL;
  char* patch_type = NULL;
  char* patch_target = NULL;

  for(size_t i = 0; i < tokens->length; i++) {
    char* current_token = list_get(tokens, i);
    #ifdef mod_lib_debug
      //printf("[LIB-DEBUG] next token: %s -- Index %zu of %zu\n", current_token, i + 1, tokens->length);
    #endif
    if(current_token[0] == '@') {
      if(strcmp(current_token, "@open") == 0) {
        if(tokens->length - i <= 2) goto cleanup;

        free(list_remove(tokens, i)); //remove @open token from the list

        //free past resources
        if(current_mod_file != NULL) {
          #ifdef mod_lib_debug
            //printf("[LIB-DEBUG] Updating file: %s\n", current_mod_dir);
          #endif
          if(!trim_tokens(current_mod_tokens)) goto cleanup;
          if(!write_file_as_tokens(&current_mod_file, current_mod_dir, current_mod_tokens)) goto cleanup; //update file

          fclose(current_mod_file);
          current_mod_file = NULL;
        }
        if(current_mod_dir != NULL) {
          free(current_mod_dir);
          current_mod_dir = NULL;
        }
        if(current_mod_tokens != NULL) {
          list_destroy(current_mod_tokens);
          current_mod_tokens = NULL;
        }

        free(list_remove(tokens, i)); //skip spacing token

        char* next_token = list_remove(tokens, i);
        size_t mod_dir_length = (strlen(context->scripts_path) + strlen(next_token) + 2);
        current_mod_dir = malloc(mod_dir_length);
        if(current_mod_dir == NULL) goto cleanup;

        current_mod_dir[0] = '\0';
        if(strcpy_s(current_mod_dir, mod_dir_length, context->scripts_path) != 0) goto cleanup;
        if(strcat_s(current_mod_dir, mod_dir_length, next_token) != 0) goto cleanup;

        #ifdef mod_lib_debug
          //printf("[LIB-DEBUG] Opening File: %s\n", current_mod_dir);
        #endif

        errno_t error = fopen_s(&current_mod_file, current_mod_dir, "r");
        if(error == ENOENT) { //file not exist, dont freak out
          #ifdef mod_lib_debug
            printf("[LIB-DEBUG] File Not Found: %s\n", current_mod_dir);
          #endif
        } else if(error != 0) {
          goto cleanup; //any other error results in early exit
        } else {
          current_mod_tokens = read_file_as_tokens(&current_mod_file);
        }

        while(i < tokens->length) { //ignore tokens until next line
          current_token = list_remove(tokens, i);
          if(strcmp(current_token, "-NEWLINE") == 0) {
            free(current_token);
            i--;
            break;
          }
          free(current_token);
        }
      } else if(strcmp(current_token, "@patch") == 0) { //patch token
        #ifdef mod_lib_debug
          //printf("[LIB-DEBUG] Beginning patch\n");
        #endif

        if(tokens->length - i <= 6) goto cleanup;

        free(list_remove(tokens, i)); //remove @patch token from the list
        free(list_remove(tokens, i)); //skip spacing token

        if(class_name != NULL) free(class_name);
        class_name = list_remove(tokens, i);

        free(list_remove(tokens, i)); //skip spacing token

        if(class_window != NULL) free(class_window);
        if(strcmp(class_name, "auto") == 0 || strcmp(class_name, "global") == 0) {
          class_window = malloc(sizeof(token_window));
          if(class_window == NULL || current_mod_tokens == NULL) goto cleanup;

          class_window->start = 0;
          class_window->end = current_mod_tokens->length - 1;
        } else {
          class_window = find_class_window(current_mod_tokens, class_name);
        }
        if(class_window == NULL) goto cleanup;

        if(patch_type != NULL) free(patch_type);
        patch_type = list_remove(tokens, i);

        free(list_remove(tokens, i)); //skip spacing token

        if(patch_target != NULL) free(patch_target);
        patch_target = list_remove(tokens, i);

        if(target_window != NULL) free(target_window);
        if(strcmp(patch_type, "function") == 0) {
          target_window = find_function_window(current_mod_tokens, class_window, patch_target);
        } else if(strcmp(patch_type, "property") == 0) {
          target_window = find_property_window(current_mod_tokens, class_window, patch_target);
        } else if(strcmp(patch_type, "enum") == 0) {
          target_window = find_enum_window(current_mod_tokens, class_window, patch_target);
        } else {
          goto cleanup;
        }

        current_token = list_remove(tokens, i);
        while(strcmp(current_token, "-NEWLINE") != 0) { //ignore tokens until next line
          if(i >= tokens->length) {
            free(current_token);
            break;
          }
          free(current_token);
          current_token = list_remove(tokens, i);
        }

        size_t start = i;

        current_token = list_get(tokens, i);
        while(token_is_spacing(current_token)) { //ignore starting spacing
          current_token = list_get(tokens, i);
          i++;
        }

        token_window patch_window;
        patch_window.start = i - 1;

        while(i < tokens->length - 1) { //ignore tokens until @end
          current_token = list_get(tokens, i);
          if(strcmp(current_token, "@end") == 0) {
            break;
          }
          i++;
        }

        patch_window.end = i - 1;

        if(target_window != NULL) {
          #ifdef mod_lib_debug
            //removal
            //printf("[LIB-DEBUG] Removing window:\n");
            //for(size_t x = target_window->start; x <= target_window->end; x++) {
            //  printf("[LIB-DEBUG]    %s\n", (char*) list_get(current_mod_tokens, x));
            //}

            //injection
            //printf("[LIB-DEBUG] Injecting window:\n");
            //for(size_t x = patch_window.start; x <= patch_window.end; x++) {
            //  printf("[LIB-DEBUG]    %s\n", (char*) list_get(tokens, x));
            //}
          #endif

          if(!remove_window_from_list(target_window, current_mod_tokens)) goto cleanup;
          if(!inject_window(current_mod_tokens, target_window->start, tokens, &patch_window)) goto cleanup;
        }

        while(i < tokens->length - 1) {
          current_token = list_get(tokens, i);
          if(strcmp(current_token, "-NEWLINE") == 0) {
            break;
          }
          i++;
        }

        patch_window.end = i;

        if(!remove_window_from_list(&patch_window, tokens)) goto cleanup;

        i = start - 1;

        #ifdef mod_lib_debug
          //printf("[LIB-DEBUG] Finished @patch\n");
        #endif
      } else if(strcmp(current_token, "@add") == 0) {
        if(tokens->length - i <= 6) goto cleanup;

        free(list_remove(tokens, i)); //remove @patch token from the list
        free(list_remove(tokens, i)); //skip spacing token

        if(class_name != NULL) free(class_name);
        class_name = list_remove(tokens, i);

        free(list_remove(tokens, i)); //skip spacing token

        if(class_window != NULL) free(class_window);
        class_window = find_class_window(current_mod_tokens, class_name);
        if(class_window == NULL) goto cleanup;

        if(patch_type != NULL) free(patch_type);
        patch_type = list_remove(tokens, i);

        free(list_remove(tokens, i)); //skip spacing token

        size_t target_index = 0xffffffffffffffffULL;

        if(strcmp(patch_type, "function") == 0 || strcmp(patch_type, "enum") == 0) {
          size_t index = class_window->end;
          
          if(current_mod_tokens == NULL) goto cleanup;

          if(class_window->scope == local) {
            while(index >= class_window->start) { //ignore tokens until @end
              char* tkn = list_get(current_mod_tokens, index);
              if(tkn[strlen(tkn) - 1] == '}') {
                break;
              }
              index--;
            }
          }

          target_index = index;
        } else if(strcmp(patch_type, "property") == 0) {

          if(current_mod_tokens == NULL) goto cleanup;
          size_t index = class_window->start;

          if(class_window->scope == local) {
            while(index < current_mod_tokens->length - 1) { //ignore tokens until { found
              char* tkn = list_get(current_mod_tokens, index);
              if(tkn[strlen(tkn) - 1] == '{') {
                break;
              }
              index++;
            }

            while(index < current_mod_tokens->length - 1) { //ignore tokens until @end
              char* tkn = list_get(current_mod_tokens, index);
              if(strcmp(tkn, "-NEWLINE")) {
                break;
              }
              index++;
            }

            target_index = index + 2;
          } else {
            target_index = index;
          }
        } else {
          goto cleanup;
        }

        if(target_index == 0xffffffffffffffffULL) goto cleanup;

        size_t start = i;

        current_token = list_get(tokens, i);
        while(token_is_spacing(current_token)) { //ignore starting spacing
          current_token = list_get(tokens, i);
          i++;
        }

        token_window patch_window;
        patch_window.start = i - 1;

        while(i < tokens->length - 1) { //ignore tokens until @end
          current_token = list_get(tokens, i);
          if(strcmp(current_token, "@end") == 0) {
            break;
          }
          i++;
        }

        patch_window.end = i - 1;

        if(!inject_window(current_mod_tokens, target_index, tokens, &patch_window)) goto cleanup;

        char* spacing_str;
        if(class_window->scope == global) {
          spacing_str = "-NEWLINE";
        } else {
          spacing_str = "-TAB";
        }

        size_t spacing_size = strlen(spacing_str) + 1;
        char* spacing = malloc(spacing_size);

        if(spacing == NULL) goto cleanup;

        if(strcpy_s(spacing, spacing_size, spacing_str) != 0) {
          free(spacing);
          goto cleanup;
        }

        if(!list_insert(current_mod_tokens, spacing, target_index)) {
          free(spacing);
          goto cleanup;
        }

        while(i < tokens->length - 1) {
          current_token = list_get(tokens, i);
          if(strcmp(current_token, "-NEWLINE") == 0) {
            break;
          }
          i++;
        }

        patch_window.end = i;

        if(!remove_window_from_list(&patch_window, tokens)) goto cleanup;

        i = start - 1;
      } else if(strcmp(current_token, "@import") == 0) {
        free(list_remove(tokens, i)); //remove @import token from the list
        free(list_remove(tokens, i)); //skip spacing token

        char* import_directive = list_remove(tokens, i);
        if(import_directive == NULL) goto cleanup;

        size_t delimited_import_directive_size = strlen(import_directive) + 2;
        char* delimited_import_directive = malloc(delimited_import_directive_size);
        if(delimited_import_directive == NULL) {
          free(import_directive);
          goto cleanup;
        }

        if(strcpy_s(delimited_import_directive, delimited_import_directive_size, import_directive) != 0) {
          free(import_directive);
          free(delimited_import_directive);
          goto cleanup;
        }

        free(import_directive);

        if(strcat_s(delimited_import_directive, delimited_import_directive_size, ";") != 0) {
          free(delimited_import_directive);
          goto cleanup;
        }

        #ifdef mod_lib_debug
          //printf("[LIB-DEBUG] Adding import: %s\n", delimited_import_directive);
        #endif

        list import_tokens = {
          .capacity = 0,
          .head = NULL,
          .length = 0,
        };

        //tokens will be ["import", "-SPACE", <import_directive + ';'>, "-NEWLINE"]
        if(!list_create_sized(&import_tokens, 4)) { //4 length to fit all tokens without resize
          free(delimited_import_directive);
          goto cleanup;
        }

        if(!list_add(&import_tokens, "import")) {
          free(delimited_import_directive);
          list_destroy(&import_tokens);
          goto cleanup;
        }
        if(!list_add(&import_tokens, "-SPACE")) {
          free(delimited_import_directive);
          list_destroy(&import_tokens);
          goto cleanup;
        }
        if(!list_add(&import_tokens, delimited_import_directive)) {
          free(delimited_import_directive);
          list_destroy(&import_tokens);
          goto cleanup;
        }
        if(!list_add(&import_tokens, "-NEWLINE")) {
          list_destroy(&import_tokens);
          goto cleanup;
        }

        token_window win = {
          .start = 0,
          .end = import_tokens.length - 1,
        };

        if(!inject_window(current_mod_tokens, 0, &import_tokens, &win)) {
          list_destroy(&import_tokens);
          goto cleanup;
        }

        while(i < tokens->length) { //ignore tokens until next line
          current_token = list_remove(tokens, i);
          if(strcmp(current_token, "-NEWLINE") == 0) {
            free(current_token);
            i--;
            break;
          }
          free(current_token);
        }
      } else {
        if(strlen(current_token) >= 3) {
          char* sub = substring(current_token, 0, 2);
          if(sub == NULL) {
            goto cleanup;
          }

          if(strcmp(sub, "@//") == 0) { //preprocessor comment token
            free(sub);
            free(list_remove(tokens, i)); //remove @// token from the list

            while(i < tokens->length) { //ignore tokens until next line
              current_token = list_remove(tokens, i);
              if(strcmp(current_token, "-NEWLINE") == 0) {
                free(current_token);
                i -= 1;
                break;
              }
              free(current_token);
            }
          } else {
            free(sub);
          }
        } else {
          goto cleanup;
        }
      }
    } else if(strcmp(current_token, "-NEWLINE") == 0) { //newline sometimes gets trimmed
      #ifdef mod_lib_debug
        //printf("[LIB-DEBUG] attempting to trim newline\n");
      #endif

      size_t j = i + 1;
      while(j < tokens->length - 1) {
        char* subtoken = list_get(tokens, j);
        if(strcmp(subtoken, "-NEWLINE") == 0) {
          while(j > i) {
            j--;
            char* removed_token = list_remove(tokens, j);
            #ifdef mod_lib_debug
              //printf("[LIB-DEBUG] removed token: %s\n", removed_token);
            #endif
            free(removed_token);
          }
          break;
        } else if(token_is_spacing(subtoken)) { //any other spacing token gets skipped
          continue;
        } else {
          break;
        }
        j++;
      }
    } else { //any normal token / any other spacing token gets ignored
      continue;
    }
  }

  if(current_mod_file != NULL) {
    #ifdef mod_lib_debug
      //printf("[LIB-DEBUG] Updating last file: %s\n", current_mod_dir);
    #endif
    if(!trim_tokens(current_mod_tokens)) goto cleanup;
    if(!write_file_as_tokens(&current_mod_file, current_mod_dir, current_mod_tokens)) goto cleanup; //update file
  }

  status = true;

  cleanup:

  if(class_window != NULL) {
    free(class_window);
    class_window = NULL;
  }
  if(target_window != NULL) {
    free(target_window);
    target_window = NULL;
  }
  if(patch_type != NULL) {
    free(patch_type);
    patch_type = NULL;
  }
  if(patch_target != NULL) {
    free(patch_target);
    patch_target = NULL;
  }
  if(current_mod_file != NULL) {
    fclose(current_mod_file);
    current_mod_file = NULL;
  }
  if(current_mod_dir != NULL) {
    free(current_mod_dir);
    current_mod_dir = NULL;
  }
  if(current_mod_tokens != NULL) {
    list_destroy(current_mod_tokens);
    current_mod_tokens = NULL;
  }
  return status;
}

bool trim_tokens(list* tokens) {
  if(tokens == NULL) return false;
  while(tokens->length > 0 && ((char*) list_get(tokens, 0))[0] == '-') { //leading whitespace
    if(!list_remove(tokens, 0)) return false;
  }

  while(tokens->length > 0 && ((char*) list_get(tokens, tokens->length - 1))[0] == '-') { //trailing whitespace
    if(!list_remove(tokens, tokens->length - 1)) return false;
  }

  return true;
}

size_t find_closing_token(list* tokens, size_t opening_token) { //returns SIZE_MAX if not found
  int counter = 0; //counter will only go back to zero once the correct bracket is found

  char* current_token = list_get(tokens, opening_token);
  char* p = strchr(current_token, '{');

  if(p == NULL) {
    #ifdef mod_lib_debug
      printf("No { in starting token\n");
    #endif
    return 0xffffffffffffffffULL;
  }

  size_t i = opening_token + 1;

  while(i < tokens->length) {
    while(*p != '\0') {
      if(*p == '{') counter++;
      if(*p == '}') counter--;

      if(counter == 0) return i;

      p++;
    }

    current_token = list_get(tokens, i);
    p = current_token;
    i++;
  }
  while(*p != '\0') {
    if(*p == '{') counter++;
    if(*p == '}') counter--;

    if(counter == 0) return i;

    p++;
  }

  #ifdef mod_lib_debug
    printf("[LIB-DEBUG] EOF before final } token\n");
  #endif
  return 0xffffffffffffffffULL; //SIZE_MAX
}


//                                     //
//                                     //
//                                     //
//              INJECTION              //
//                                     //
//                                     //
//                                     //


token_window* find_class_window(list* token_list, char* class_name) {
  #ifdef mod_lib_debug
    //printf("[LIB-DEBUG] Trying to find class: %s\n", class_name);
  #endif

  if(token_list == NULL) return NULL;

  token_window* window = malloc(sizeof(token_window));
  token_window* return_value = NULL;

  if(window == NULL) return NULL;

  window->start = 0;
  window->end = 0;

  size_t i = 0;
  char* token;

  find_class_def:
  size_t class_start = 0xffffffffffffffffULL;

  if(strcmp("global", class_name) == 0) goto global_window;

  while(i < token_list->length) {
    if(i >= token_list->length) goto cleanup;
    token = list_get(token_list, i);

    if(strcmp(token, "class") == 0 || strcmp(token, "struct") == 0) {
      #ifdef mod_lib_debug
        //printf("[LIB-DEBUG] class keyword found at idx: %zu\n", i);
      #endif
      class_start = i;

      break;
    }

    i++;
  }

  global_window:
  if(class_start == 0xffffffffffffffffULL || i >= token_list->length - 1) {
    if(strcmp("auto", class_name) == 0 || strcmp("global", class_name) == 0) {
      i = 0;
      token = list_get(token_list, i);
      if(token == NULL) goto cleanup;

      while(strcmp(token, "import") == 0) {
        while(strcmp(token, "-NEWLINE") != 0) {
          i++;
          token = list_get(token_list, i);
        }
        while(token_is_spacing(token)) {
          i++;
          token = list_get(token_list, i);
        }
        i++;
        token = list_get(token_list, i);
      }

      window->start = i - 1;
      window->end = token_list->length;
      window->scope = global;

      return_value = window;
      goto cleanup;
    } else {
      goto cleanup;
    }
  }

  if(i >= token_list->length) goto cleanup;

  token = list_get(token_list, ++i);
  while(token_is_spacing(token)) {
    if(i >= token_list->length) goto cleanup;

    token = list_get(token_list, i);
    i++;
  }

  if(strcmp("auto", class_name) != 0 && strcmp(token, class_name) != 0) {
    #ifdef mod_lib_debug
      //printf("[LIB-DEBUG] token / classname mismatch: %s / %s\n", token, class_name);
    #endif
    goto find_class_def; //find next class definition
  } else {
    #ifdef mod_lib_debug
      //printf("[LIB-DEBUG] classname found at token idx: %zu\n", --i);
    #endif
  }

  window->start = class_start;

  while(strchr(token, '{') == NULL) {
    if(i >= token_list->length) goto cleanup;
    token = list_get(token_list, i);
    i++;
  }

  i = find_closing_token(token_list, --i);
  if(i == 0xffffffffffffffffULL) goto cleanup;

  while(strcmp(token, "-NEWLINE") != 0) { //skip tokens until newline
    if(i >= token_list->length) {
      window->end = token_list->length; //file ended so end window there
      break;
    }
    token = list_get(token_list, i);
    i++;
  }
  window->end = --i;
  window->scope = local;
  return_value = window;

  cleanup:
  if(return_value == NULL) {
    free(window);
  } else {
    #ifdef mod_lib_debug
      //printf("[LIB-DEBUG] Class window - %s | Start: [idx: %zu, value: \"%s\"] | End: [idx: %zu, value: \"%s\"]\n", class_name, window->start, (char*) list_get(token_list, window->start), window->end, (char*) list_get(token_list, window->end));
    #endif
  }
  return return_value;
}

token_window* find_function_window(list* token_list, token_window* class_window, char* function_name) {
  #ifdef mod_lib_debug
    //printf("[LIB-DEBUG] Trying to find function: %s\n", function_name);
  #endif
  token_window* return_value = NULL;
  token_window* window = malloc(sizeof(token_window));
  size_t i = class_window->start;

  size_t function_declaration_length = strlen(function_name) + 2;
  char* function_declaration = malloc(function_declaration_length);
  if(function_declaration == NULL) goto cleanup;

  function_declaration[0] = '\0';
  if(strcpy_s(function_declaration, function_declaration_length, function_name) != 0) goto cleanup;
  if(strcat_s(function_declaration, function_declaration_length, "(") != 0) goto cleanup;

  #ifdef mod_lib_debug
    //printf("[LIB-DEBUG] Searching for token beginning in %s\n", function_declaration);
  #endif

  while(i <= class_window->end) {
    char* token = list_get(token_list, i);
    char* sub = substring(token, 0, function_declaration_length - 2);
    if(sub == NULL) goto cleanup;

    if(strcmp(function_declaration, sub) == 0) {
      free(sub);
      sub = NULL;

      window->start = i - 2;

      while(i <= class_window->end) {
        token = list_get(token_list, i);

        if(token[strlen(token) - 1] == '{') {
          i = find_closing_token(token_list, i);
          if(i == 0xffffffffffffffffULL) goto cleanup;

          while(strcmp(token, "-NEWLINE") != 0) { //skip tokens until newline
            if(i >= token_list->length) {
              window->end = token_list->length - 1; //file ended so end window there
              break;
            }
            token = list_get(token_list, i);
            i++;
          }

          window->end = --i;
          return_value = window;

          #ifdef mod_lib_debug
            //printf("[LIB-DEBUG] Found function declaration at token: %zu\n", window->start + 2);
          #endif
          break;
        } else if(token[strlen(token) - 1] == ';') {
          break;
        }
        i++;
      }
    } else {
      free(sub);
      sub = NULL;
    }
    i++;
  }

  cleanup:
  if(return_value == NULL && window != NULL) {
    free(window);
    window = NULL;
  }

  if(function_declaration != NULL) {
    free(function_declaration);
    function_declaration = NULL;
  }

  if(return_value != NULL) {
    #ifdef mod_lib_debug
      //printf("[LIB-DEBUG] Function window - %s | Start: [idx: %zu, value: \"%s\"] | End: [idx: %zu, value: \"%s\"]\n", function_name, window->start, (char*) list_get(token_list, window->start), window->end, (char*) list_get(token_list, window->end));
    #endif
  }

  return return_value;
}

token_window* find_enum_window(list* token_list, token_window* class_window, char* enum_name) {
  #ifdef mod_lib_debug
    printf("[LIB-DEBUG] Trying to find enum: %s\n", enum_name);
  #endif
  token_window* return_value = NULL;
  token_window* window = malloc(sizeof(token_window));
  size_t i = class_window->start;

  #ifdef mod_lib_debug
    printf("[LIB-DEBUG] Searching for enum token\n");
  #endif

  while(i <= class_window->end) {
    char* token = list_get(token_list, i);

    if(strcmp(token, "enum") == 0) {
      if(strcmp(list_get(token_list, i + 2), enum_name) != 0) continue; //wrong enum

      #ifdef mod_lib_debug
        printf("[LIB-DEBUG] Found enum declaration at token: %zu\n", i);
      #endif
      window->start = i;

      while(i <= class_window->end) {
        token = list_get(token_list, i);

        if(token[strlen(token) - 1] == '{') {
          i = find_closing_token(token_list, i);
          if(i == 0xffffffffffffffffULL) goto cleanup;

          while(strcmp(token, "-NEWLINE") != 0) { //skip tokens until newline
            if(i >= token_list->length) {
              window->end = token_list->length - 1; //file ended so end window there
              break;
            }
            token = list_get(token_list, i);
            i++;
          }

          window->end = --i;
          return_value = window;
          goto cleanup;
        }
        i++;
      }
    }
    i++;
  }

  cleanup:
  if(return_value == NULL && window != NULL) {
    free(window);
    window = NULL;
  }

  if(return_value != NULL) {
    #ifdef mod_lib_debug
      printf("[LIB-DEBUG] Enum window - %s | Start: [idx: %zu, value: \"%s\"] | End: [idx: %zu, value: \"%s\"]\n", enum_name, window->start, (char*) list_get(token_list, window->start), window->end, (char*) list_get(token_list, window->end));
    #endif
  }

  return return_value;
}

token_window* find_property_window(list* token_list, token_window* class_window, char* property_name) {
  #ifdef mod_lib_debug
    //printf("[LIB-DEBUG] Trying to find property: %s\n", property_name);
  #endif
  token_window* return_value = NULL;
  token_window* window = malloc(sizeof(token_window));
  size_t i = class_window->start;

  size_t delimited_property_identifier_length = strlen(property_name) + 2;
  char* delimited_property_identifier = malloc(delimited_property_identifier_length);
  if(delimited_property_identifier == NULL) goto cleanup;

  delimited_property_identifier[0] = '\0';
  if(strcpy_s(delimited_property_identifier, delimited_property_identifier_length, property_name) != 0) goto cleanup;
  if(strcat_s(delimited_property_identifier, delimited_property_identifier_length, ";") != 0) goto cleanup;

  while(i <= class_window->end) {
    char* token = list_get(token_list, i);
    if(strcmp(token, delimited_property_identifier) == 0) { //format case: Type property;
      window->start = i - 2;

      while(strcmp(token, "-NEWLINE") != 0) { //skip tokens until newline
        if(i >= class_window->end) goto cleanup;
        token = list_get(token_list, i);
        i++;
      }

      window->end = i - 1;
      return_value = window;
      break;
    }

    if(strcmp(token, property_name) == 0) { //format case: Type property = value;
      if(strcmp(list_get(token_list, i + 2), "=") != 0) goto cleanup; //invalid format
      
      window->start = i - 2;

      while(strcmp(token, "-NEWLINE") != 0) { //skip tokens until newline
        if(i >= class_window->end) goto cleanup;
        token = list_get(token_list, i);
        i++;
      }

      window->end = i - 1;
      return_value = window;
      break;
    }
    i++;
  }

  cleanup:
  free(delimited_property_identifier);
  if(return_value == NULL) {
    free(window);
  } else {
    #ifdef mod_lib_debug
      //printf("[LIB-DEBUG] Property window - %s | Start: [idx: %zu, value: \"%s\"] | End: [idx: %zu, value: \"%s\"]\n", property_name, window->start, (char*) list_get(token_list, window->start), window->end, (char*) list_get(token_list, window->end));
    #endif
  }
  return return_value;
}

bool inject_window(list* target_list, size_t target_index, list* source_list, token_window* source_window) {
  char* ending_token = list_get(source_list, source_window->end);
  if(ending_token == NULL) return false;

  char* token = NULL;
  size_t idx = source_window->start;
  size_t i = 0;

  while(token != ending_token) {
    if(token != NULL) {
      char* new_token = strdup(token);
      if(new_token == NULL) return false;

      #ifdef mod_lib_debug
        //printf("[LIB-DEBUG] injecting token: %s\n", new_token);
      #endif

      if(!list_insert(target_list, new_token, target_index + i)) {
        free(new_token);
        return false;
      }

      i++;
    }
    token = list_get(source_list, idx);
    idx++;
    if(token == NULL) return false;
  }

  char* new_token = strdup(token);
  if(new_token == NULL) return false;
  if(!list_insert(target_list, new_token, target_index + i)) {
    free(new_token);
    return false;
  }

  return true;
}


//                                     //
//                                     //
//                                     //
//              FILE UTILS             //
//                                     //
//                                     //
//                                     //


const char* get_file_extension(const char* file_name) {
  const char *dot = strrchr(file_name, '.');
  if(!dot || dot == file_name) return "";
  return dot;
}

bool file_exists(char* filepath) {
  struct _stat64 stat_buffer;
  return (_stat64(filepath, &stat_buffer) == 0);
}

bool make_path(char* filepath) {
  size_t dir_capacity = strlen(filepath) + 1;
  char* dir = malloc(dir_capacity);

  if(strcpy_s(dir, dir_capacity, filepath) != 0) {
    free(dir);
    return false;
  }

  //normalize path to be only forward slashes
  for(size_t i = 0; i < dir_capacity - 1; i++) {
    if(dir[i] == '\\') dir[i] = '/';
  }

  char* dir_end = strrchr(dir, '/');
  if(dir_end == NULL) {
    free(dir);
    return true;
  }
  *dir_end = '\0';

  char* p = dir;
  if(p[0] != '\0' && p[1] == ':') { //skip drive identifier if present
    p += 2;
  }

  while(*p != '\0') { //loop through whole string
    if(*p == '/') { //untracked / character gets skipped
      p += 1;
      continue;
    }

    char* next_slash = strchr(p, '/');
    if(next_slash != NULL) {
      *next_slash = '\0';
    }

    if(!file_exists(dir)) {
      if(_mkdir(dir) != 0) {
        printf("[LIB-DEBUG] FAILED MKDIR: %s\n", dir);
        free(dir);
        return false;
      }
    }

    if(next_slash != NULL) {
      *next_slash = '/'; //restore slash to path
      p = next_slash + 1;
    } else {
      break;
    }
  }

  free(dir);
  return true;
}

list* read_file_as_tokens(FILE** file) {
  if(file == NULL || *file == NULL) return NULL;

  fseek(*file, 0, SEEK_END);
  long buffer_size = ftell(*file);
  fseek(*file, 0, SEEK_SET);

  char* file_contents = malloc(buffer_size + 1);
  if(file_contents == NULL) {
    return NULL;
  }

  size_t file_size = fread_s(file_contents, buffer_size, sizeof(char), buffer_size / sizeof(char), *file);
  file_contents[buffer_size] = '\0';

  list* tokens = get_tokens(file_contents, file_size);
  if(tokens == NULL) {
    free(file_contents);
    return NULL;
  }

  free(file_contents);
  return tokens;
}

bool write_file_as_tokens(FILE** file, const char* file_path, list* tokens) {
  if(file == NULL || tokens == NULL) return false;

  if(*file != NULL) {
    fclose(*file);
    *file = NULL;
  }

  if(fopen_s(file, file_path, "w") != 0) return false; //empty the file and open it for writing

  #ifdef mod_lib_debug
    //printf("[LIB-DEBUG] Writing to File: %s\n", file_path);
  #endif

  for(size_t i = 0; i < tokens->length; i++) {
    char* current_token = list_get(tokens, i);

    #ifdef mod_lib_debug
      //printf("[LIB-DEBUG] Writing Token: %s -- Index %zu of %zu\n", current_token, i + 1, tokens->length);
    #endif

    int result = EOF;

    if(strcmp(current_token, "-NEWLINE") == 0) {
      result = fputs("\n", *file);
    } else if(strcmp(current_token, "-TAB") == 0) {
      result = fputs("    ", *file);
    } else if(strcmp(current_token, "-SPACE") == 0) {
      result = fputs(" ", *file);
    } else {
      result = fputs(current_token, *file);
    }

    if(result == EOF) return false;
  }

  fflush(*file);

  return true;
}


//                                     //
//                                     //
//                                     //
//            STRING UTILS             //
//                                     //
//                                     //
//                                     //


char* substring(char* string, int start, int end) {
  if(end < start) return NULL;

  size_t size = end - start + 2;

  char* sub = malloc(size);
  if(sub == NULL) return NULL;

  if(memcpy_s(sub, size, string + start, size - 1) != 0) {
    free(sub);
    return NULL;
  }

  sub[size - 1] = '\0';

  return sub;
}

bool token_is_spacing(char* token) {
  if(strcmp(token, "-SPACE") == 0) return true;
  if(strcmp(token, "-NEWLINE") == 0) return true;
  if(strcmp(token, "-TAB") == 0) return true;

  return false;
}


//                                     //
//                                     //
//                                     //
//                LIST                 //
//                                     //
//                                     //
//                                     //


bool list_create_sized(struct tstd_list_t* list, size_t capacity) {
  if(list == NULL) return false;
  list->capacity = capacity;
  list->length = 0;
  list->head = calloc(capacity, sizeof(void*));
  return list->head != NULL; //return status of malloc
}

bool list_create_empty(struct tstd_list_t* list) {
  if(list == NULL) return false;
  list->capacity = 0;
  list->length = 0;
  list->head = NULL;
  return true;
}

bool list_add(struct tstd_list_t* list, void* item) {
  if(list == NULL) return 0;
  if((list_is_empty(list) && list->capacity < 1) || list->length >= list->capacity) {
    unsigned int capacity = list->capacity == 0 ? 16 : (list->capacity * 2);
  
    if(!list_resize(list, __max(list->length, capacity))) {
      return false;
    }
  }
  list->head[list->length] = item;
  list->length++;
  return true;
}

void* list_pop(struct tstd_list_t* list) {
  if(list_is_empty(list)) {
    return NULL;
  }

  //remove item
  void* temp;
  temp = list->head[list->length - 1];
  list->head[list->length - 1] = NULL;
  list->length--;

  //resize to 50% capacity if length is 25% of capacity (16 minimum capacity)
  if(list->length > 16 && list->length <= list->capacity / 4) {
    list_resize(list, list->capacity / 2);
  }

  return temp;
}

void* list_remove(struct tstd_list_t* list, size_t index) {
  if(list_is_empty(list) || index >= list->length) {
    return NULL;
  }

  //remove item
  void* temp;
  temp = list->head[index];

  //shift list to fill the gap
  for(unsigned long long i = index + 1; i < list->length; i++) {
    list->head[i - 1] = list->head[i];
  }

  list->length--;

  //resize to 50% capacity if length is 25% of capacity (16 minimum capacity)
  if(list->length > 16 && list->length <= list->capacity / 4) {
    list_resize(list, __max(list->length, list->capacity / 2));
  }

  return temp;
}

bool list_insert(struct tstd_list_t* list, void* item, size_t index) {
  if(list == NULL || index > list->length) return 0;

  if((list_is_empty(list) && list->capacity < 1) || list->length >= list->capacity) {
    size_t capacity = list->capacity == 0 ? 16 : (list->capacity * 2);
  
    if(!list_resize(list, __max(list->length, capacity))) {
      return false;
    }
  }

  //shift items to create a gap
  if (index < list->length) {
    if(memmove_s(&list->head[index + 1], (list->capacity - (index + 1)) * sizeof(void*), &list->head[index], (list->length - index) * sizeof(void*)) != 0) return false;
  }

  list->head[index] = item;
  list->length++;
  return true;
}

void* list_get(struct tstd_list_t* list, size_t index) {
  if(list_is_empty(list) || index >= list->length) {
    return NULL;
  }

  return list->head[index];
}

void list_destroy(struct tstd_list_t* list) {
  if(list != NULL) {
    if(list->head != NULL) {
      for(unsigned long long i = 0; i < list->length; i++) {
        if(list->head[i] != NULL) free(list->head[i]);
      }
      free(list->head);
    }

    list->head = NULL;
    list->capacity = 0;
    list->length = 0;

    free(list);
  }
}

bool list_resize(struct tstd_list_t* list, size_t capacity) {
  if(list == NULL || capacity < list->length) {
    return false;
  }

  void** p = (void**) realloc(list->head, sizeof(void*) * capacity);

  if(p == NULL) return false;

  for (unsigned long long i = list->capacity; i < capacity; i++) {
    p[i] = NULL;
  }

  if(p == NULL) {
    return false;
  } else {
    list->head = p;
    list->capacity = capacity;
  }
  return true;
}

bool list_is_empty(struct tstd_list_t* list) {
  return (list == NULL || list->length == 0 || list->head == NULL || list->capacity == 0);
}


//                                     //
//                                     //
//                                     //
//            TOKEN WINDOW             //
//                                     //
//                                     //
//                                     //


struct mod_lib_token_window_t* token_window_create(size_t start, size_t end) {
  struct mod_lib_token_window_t* window = malloc(sizeof(struct mod_lib_token_window_t));

  if(window == NULL) return NULL;

  window->start = start;
  window->end = end;

  return window;
}

bool remove_window_from_list(struct mod_lib_token_window_t* window, list* token_list) {
  #ifdef mod_lib_debug
    //printf("[LIB-DEBUG] attempting to remove window [%zu..%zu] from list: [0..%zu]\n", window->start, window->end, token_list->length - 1);
  #endif
  char* ending_token = list_get(token_list, window->end);
  if(ending_token == NULL) return false;

  char* token = NULL;

  while(token != ending_token) {
    if(token != NULL) free(token);
    token = list_remove(token_list, window->start);
    if(token == NULL) return false;
  }
  free(token);

  #ifdef mod_lib_debug
    //printf("[LIB-DEBUG] successful removal from list\n");
  #endif
  return true;
}