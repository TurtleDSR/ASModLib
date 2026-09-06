import Rice.MainMenu.LobbyWidget;
import Rice.ChapterSelect.ChapterSelectPickerWidget;
import Rice.MinigamePicker.MinigamePickerWidget;
import Rice.MainMenu.MainMenuWidget;
import Rice.MainMenu.MenuPromptOrButton;

event void FOnCategoryPressed();

const FConsoleVariable CVar_AlwaysShowFriendsPassPopup("Haze.AlwaysShowFriendsPassPopup", 0);

struct FChapterSelectButtons
{
	// Top Banner
	UPROPERTY()
	UChapterSelectCategoryWidget NewGame;

	UPROPERTY()
	UChapterSelectCategoryWidget Continue;

	UPROPERTY()
	UChapterSelectCategoryWidget ChapterSelect;

	UPROPERTY()
	UChapterSelectCategoryWidget Minigames;

	// Controls
	UPROPERTY()
	UMenuPromptOrButton LeftTab;

	UPROPERTY()
	UMenuPromptOrButton RightTab;

	UPROPERTY()
	UMenuPromptOrButton Back;

	UPROPERTY()
	UMenuPromptOrButton Invite;

	UPROPERTY()
	UMenuPromptOrButton FP;

	UPROPERTY()
	UMenuPromptOrButton Proceed;
}

class UChapterSelectCategoryWidget : UHazeUserWidget
{
	default Visibility = ESlateVisibility::Visible;

	UPROPERTY()
	FText Text;

	UPROPERTY()
	bool bIsSelected = false;

	UPROPERTY()
	bool bIsButtonEnabled = true;

	private bool bHovered = false;

	UPROPERTY()
	FOnCategoryPressed OnPressed;

	UFUNCTION(BlueprintPure)
	bool IsButtonHovered()
	{
		auto Lobby = Lobby::GetLobby();
		if (Lobby != nullptr && Lobby.Network == EHazeLobbyNetwork::Join)
			return false;
		return bHovered && bIsButtonEnabled;
	}

	UFUNCTION(BlueprintPure)
	bool IsClickableByMouse()
	{
		return !Game::IsConsoleBuild();
	}

	UFUNCTION(BlueprintPure)
	bool IsButtonEnabledOrRemote()
	{
		auto Lobby = Lobby::GetLobby();
		if (Lobby != nullptr && Lobby.Network == EHazeLobbyNetwork::Join)
			return true;
		return bIsButtonEnabled;
	}

	UFUNCTION(BlueprintPure)
	bool IsUsableByController()
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnMouseEnter(FGeometry Geom, FPointerEvent MouseEvent)
	{
		auto Lobby = Lobby::GetLobby();
		if (Lobby != nullptr && Lobby.Network == EHazeLobbyNetwork::Join)
			return;

		if(!bIsSelected)
		{
			UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_Menu_ButtonHover_TriggerRate", 0.f);
			GetAudioManager().UI_OnSelectionChanged_Hover_Background_Mouse();
		}

		Game::NarrateText(Text);

		bHovered = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnMouseLeave(FPointerEvent MouseEvent)
	{
		bHovered = false;
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonDown(FGeometry Geom, FPointerEvent Event)
	{
		if (Event.EffectingButton == EKeys::LeftMouseButton)
		{
			return FEventReply::Handled();
		}
		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonUp(FGeometry Geom, FPointerEvent Event)
	{
		if (Event.EffectingButton == EKeys::LeftMouseButton)
		{
			if (bIsButtonEnabled)
				OnPressed.Broadcast();
			return FEventReply::Handled();
		}
		return FEventReply::Unhandled();
	}
};

enum EFriendListState
{
	None,
	InviteChoice,
	FriendList,
	FriendAction,
	FriendSearch,
	FriendSearchAction,
	BlockList,
	BlockListAction,
	HostChoice,
};

class UChapterSelectWidget : ULobbyWidget
{
	UPROPERTY()
	UChapterSelectPickerWidget ChapterPicker;
	UPROPERTY()
	UMinigamePickerWidget MinigamePicker;

	UPROPERTY(Meta = (BindWidget))
	UMenuPromptOrButton InviteButton;

	UPROPERTY(Meta = (BindWidget))
	UWidget MainContainer;

	UPROPERTY(Meta = (BindWidget))
	UMainMenuButtonWidget SendInviteChoiceButton_Origin;
	UPROPERTY(Meta = (BindWidget))
	UMainMenuButtonWidget SendInviteChoiceButton_Steam;
	UPROPERTY(Meta = (BindWidget))
	UMainMenuButtonWidget ManageEAFriendsButton;
	UPROPERTY(Meta = (BindWidget))
	UMenuPromptOrButton CancelInviteChoiceButton;
	UPROPERTY(Meta = (BindWidget))
	UWidget InviteChoicePopup;

	UPROPERTY(Meta = (BindWidget))
	UWidget HostChoicePopup;
	UPROPERTY(Meta = (BindWidget))
	UMainMenuButtonWidget HostChoiceButton_Steam;
	UPROPERTY(Meta = (BindWidget))
	UMainMenuButtonWidget HostChoiceButton_EA;
	UPROPERTY(Meta = (BindWidget))
	UMenuPromptOrButton CancelHostChoiceButton;

	UPROPERTY(Meta = (BindWidget))
	UWidget FriendListPopup;
	UPROPERTY(Meta = (BindWidget))
	UListView FriendList;
	UPROPERTY(Meta = (BindWidget))
	UWidget FriendListLoadingSpinner;
	UPROPERTY(Meta = (BindWidget))
	UMenuPromptOrButton CloseFriendsListButton;
	UPROPERTY(Meta = (BindWidget))
	UMenuPromptOrButton AddFriendButton;
	UPROPERTY(Meta = (BindWidget))
	UMenuPromptOrButton BlockListButton;
	UPROPERTY(Meta = (BindWidget))
	UTextBlock EAAccountNameText;

	UPROPERTY(Meta = (BindWidget))
	UWidget FriendActionPopup;
	UPROPERTY(Meta = (BindWidget))
	UTextBlock FriendActionName;
	UPROPERTY(Meta = (BindWidget))
	UMainMenuButtonWidget FriendAction_JoinOnlineLobby;
	UPROPERTY(Meta = (BindWidget))
	UMainMenuButtonWidget FriendAction_InviteToGame;
	UPROPERTY(Meta = (BindWidget))
	UMainMenuButtonWidget FriendAction_InviteToGame_Steam;
	UPROPERTY(Meta = (BindWidget))
	UMainMenuButtonWidget FriendAction_InviteToGame_EA;
	UPROPERTY(Meta = (BindWidget))
	UMainMenuButtonWidget FriendAction_AcceptFriendRequest;
	UPROPERTY(Meta = (BindWidget))
	UMainMenuButtonWidget FriendAction_DeclineFriendRequest;
	UPROPERTY(Meta = (BindWidget))
	UMainMenuButtonWidget FriendAction_CancelFriendRequest;
	UPROPERTY(Meta = (BindWidget))
	UMainMenuButtonWidget FriendAction_Unblock;
	UPROPERTY(Meta = (BindWidget))
	UMainMenuButtonWidget FriendAction_Block;
	UPROPERTY(Meta = (BindWidget))
	UMainMenuButtonWidget FriendAction_Unfriend;
	UPROPERTY(Meta = (BindWidget))
	UMainMenuButtonWidget FriendAction_RequestFriend;
	UPROPERTY(Meta = (BindWidget))
	UMainMenuButtonWidget FriendAction_Close;

	UPROPERTY(Meta = (BindWidget))
	UWidget FriendSearchPopup;
	UPROPERTY(Meta = (BindWidget))
	UListView SearchList;
	UPROPERTY(Meta = (BindWidget))
	UEditableTextBox SearchInputBox;
	UPROPERTY(Meta = (BindWidget))
	UMenuPromptOrButton CloseFriendSearchButton;

	UPROPERTY(Meta = (BindWidget))
	UWidget BlockListPopup;
	UPROPERTY(Meta = (BindWidget))
	UListView BlockList;
	UPROPERTY(Meta = (BindWidget))
	UMenuPromptOrButton CloseBlockListButton;

	FKCodeHandler KCodeHandler;

	default bCustomNavigation = true;

	bool bHasContinue = false;
	bool bInFriendsPassPopup = false;
	EFriendListState FriendListState = EFriendListState::None;
	UHazeOnlineFriend ActionFriend;

	float EngagementGraceTimer = 0.f;
	FHazeProgressPointRef ContinueChapter;
	FHazeProgressPointRef ContinuePoint;
	EHazeLobbyStartType CurrentStartType = EHazeLobbyStartType::NewGame;

	bool bAwaitingFocus = false;
	EFocusCause AwaitingFocusCause;
	float RefreshTimer = 0.4;

	TArray<UObject> FriendObjects;
	TArray<UHazeOnlineFriend> Friends;

	TArray<UObject> SearchObjects;
	TArray<UHazeOnlineFriend> SearchFriends;

	TArray<UObject> BlockListObjects;
	TArray<UHazeOnlineFriend> BlockListFriends;

	private bool bNarrateNextTick = false;

	private FString ConinueNarrationText = "";

	int PlayersInLobby = 1;
	private bool bHasTickedForSound = false;
	private UHazeLobby PrevLobby = nullptr;

	private bool bWasFriendsChoiceFocused = false;

	private bool bIsPC = false;
	private bool bIsOrigin = false;
	private bool bIsSteam = false;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		ChapterPicker.OnChapterSelectChanged.AddUFunction(this, n"OnChapterPickerChanged");
		MinigamePicker.OnMinigameSelected.AddUFunction(this, n"OnMinigamePicked");

		SendInviteChoiceButton_Steam.OnPressed.AddUFunction(this, n"OnSendInviteChoice");
		SendInviteChoiceButton_Origin.OnPressed.AddUFunction(this, n"OnSendInviteChoice");
		ManageEAFriendsButton.OnPressed.AddUFunction(this, n"OnManageFriendsChoice");

		CloseFriendsListButton.OnPressed.AddUFunction(this, n"OnCloseFriendsList");
		AddFriendButton.OnPressed.AddUFunction(this, n"OnAddFriend");
		BlockListButton.OnPressed.AddUFunction(this, n"OnBlockList");

		FriendAction_JoinOnlineLobby.OnPressed.AddUFunction(this, n"OnFriendAction_JoinOnlineLobby");
		FriendAction_InviteToGame.OnPressed.AddUFunction(this, n"OnFriendAction_InviteToGame");
		FriendAction_InviteToGame_Steam.OnPressed.AddUFunction(this, n"OnFriendAction_InviteToGame_Steam");
		FriendAction_InviteToGame_EA.OnPressed.AddUFunction(this, n"OnFriendAction_InviteToGame_EA");
		FriendAction_AcceptFriendRequest.OnPressed.AddUFunction(this, n"OnFriendAction_AcceptFriendRequest");
		FriendAction_DeclineFriendRequest.OnPressed.AddUFunction(this, n"OnFriendAction_DeclineFriendRequest");
		FriendAction_CancelFriendRequest.OnPressed.AddUFunction(this, n"OnFriendAction_CancelFriendRequest");
		FriendAction_Unblock.OnPressed.AddUFunction(this, n"OnFriendAction_Unblock");
		FriendAction_Block.OnPressed.AddUFunction(this, n"OnFriendAction_Block");
		FriendAction_Unfriend.OnPressed.AddUFunction(this, n"OnFriendAction_Unfriend");
		FriendAction_RequestFriend.OnPressed.AddUFunction(this, n"OnFriendAction_RequestFriend");
		FriendAction_Close.OnPressed.AddUFunction(this, n"OnFriendAction_Close");

		CloseFriendSearchButton.OnPressed.AddUFunction(this, n"CloseSearch");
		SearchInputBox.OnTextChanged.AddUFunction(this, n"OnSearchTextChanged");

		CloseBlockListButton.OnPressed.AddUFunction(this, n"CloseBlockList");

		HostChoiceButton_Steam.OnPressed.AddUFunction(this, n"OnHostChoiceSteam");
		HostChoiceButton_EA.OnPressed.AddUFunction(this, n"OnHostChoiceEA");
		CancelHostChoiceButton.OnPressed.AddUFunction(this, n"CancelHostChoice");
	}

	UFUNCTION(BlueprintOverride)
	void Show(bool bSnap)
	{
		Super::Show(bSnap);

		if (Lobby == nullptr)
			return;

		// Select continue in chapter select if available
		if (Lobby.LobbyOwner.IsLocal())
		{
			bHasContinue = Save::GetContinueProgress(ContinueChapter, ContinuePoint);
			if (bHasContinue)
			{
				FHazeChapter Chapter = ChapterDatabase.GetChapterByProgressPoint(ContinueChapter);
				FHazeChapterGroup Group = ChapterDatabase.GetChapterGroup(Chapter);

				BP_SetContinueChapter(Group, Chapter);
				ConinueNarrationText = Group.GroupName.ToString() + ", " + Chapter.Name.ToString() + ", ";

				bool bNewLobby = Lobby != PrevLobby;
				if (bNewLobby)
				{
					if (Lobby.StartType == EHazeLobbyStartType::NewGame || Lobby.StartType == EHazeLobbyStartType::Continue)
					{
						if (Save::IsContinueStartable(ContinueChapter, ContinuePoint))
							ChapterPicker.SelectChapter(Chapter.ProgressPoint);
						else
							ChapterPicker.SelectChapter(ChapterDatabase.GetInitialChapter());

						Lobby::Menu_LobbySelectStart(EHazeLobbyStartType::Continue, ContinueChapter, ContinuePoint);
					}
					else
					{
						ChapterPicker.SelectChapter(Lobby.StartChapter);
					}
				}
			}

			MainMenu.bIsNewLobby = false;
		}

		PrevLobby = Lobby;

		// Unselect a character if we have any selected
		for (auto& Member : Lobby.LobbyMembers)
		{
			if (Member.Identity != nullptr && Member.Identity.IsLocal()
				&& Member.ChosenPlayer != EHazePlayer::MAX)
			{
				Lobby::Menu_LobbySetReady(Member.Identity, false);
				Lobby::Menu_LobbySelectPlayer(Member.Identity, EHazePlayer::MAX);
			}
		}

		// Prepare minigame picker
		MinigamePicker.Initialize();
		if (Lobby.LobbyOwner.IsLocal())
		{
			if (Lobby.StartType == EHazeLobbyStartType::PickMinigame)
				MinigamePicker.SelectMinigame(Lobby.StartProgressPoint, false);
		}

		FString OnlinePlatformName = Online::GetOnlinePlatformName();
		if (OnlinePlatformName == "Origin")
		{
			bIsPC = true;
			bIsOrigin = true;
		}
		else if (OnlinePlatformName == "Steam")
		{
			bIsPC = true;
			bIsSteam = true;
		}
		else if (OnlinePlatformName == "Editor")
		{
			// Play pretend for in-editor testing
			bIsPC = true;
			bIsSteam = true;
			bIsOrigin = false;
		}

		if (bIsSteam)
		{
			SendInviteChoiceButton_Origin.Visibility = ESlateVisibility::Collapsed;
		}
		else
		{
			SendInviteChoiceButton_Steam.Visibility = ESlateVisibility::Collapsed;
		}

		FriendListState = EFriendListState::None;
		MainContainer.Visibility = ESlateVisibility::Visible;
		if (Lobby != nullptr && Lobby.Network == EHazeLobbyNetwork::Host)
		{
			StartLobbyHost();

			if (Online::GetGameServerMode() == EHazeGameServerMode::DelayHosting)
				PromptForHostType();
			else
				MaybeShowFriendsPassInfo();
		}

		CancelInviteChoiceButton.Text = NSLOCTEXT("ChapterSelect", "CancelPrompt", "Cancel");
		CancelInviteChoiceButton.Update();
		CancelInviteChoiceButton.OnPressed.AddUFunction(this, n"CancelInviteChoice");

		CancelHostChoiceButton.Text = NSLOCTEXT("ChapterSelect", "CancelPrompt", "Cancel");
		CancelHostChoiceButton.Update();

		EAAccountNameText.SetText(FText::FromString(Online::GetEAUsername()));

		BindMemberEvents(GetLobbyOwnerWidget());
		BindMemberEvents(GetLobbyJoinerWidget());
		PlayersInLobby = 1;
		bHasTickedForSound = false;
	}


	void PromptForHostType()
	{
		FriendListState = EFriendListState::HostChoice;
		UpdateFriendList();

		GetAudioManager().UI_PopupMessageOpen();

		Widget::SetAllPlayerUIFocus(HostChoiceButton_Steam);
		MainContainer.Visibility = ESlateVisibility::Hidden;
	}

	UFUNCTION()
	void OnHostChoiceSteam()
	{
		Online::SetGameServerMode(EHazeGameServerMode::UseSteamGameServers);

		FriendListState = EFriendListState::None;
		UpdateFriendList();
		MaybeShowFriendsPassInfo();

		System::SetTimer(this, n"OnMakeLobbyVisible", 0.25f, false);
	}

	UFUNCTION()
	void OnHostChoiceEA()
	{
		Online::SetGameServerMode(EHazeGameServerMode::Default);

		FriendListState = EFriendListState::None;
		UpdateFriendList();
		MaybeShowFriendsPassInfo();

		System::SetTimer(this, n"OnMakeLobbyVisible", 0.25f, false);
	}

	UFUNCTION()
	private void OnMakeLobbyVisible()
	{
		if (MainContainer != nullptr)
			MainContainer.Visibility = ESlateVisibility::Visible;
	}

	void MaybeShowFriendsPassInfo()
	{
		// Show friends pass popup if it's the first time we've gone online
		if (ShouldShowFriendsPassInfo())
		{
			FString ShownValue;
			if (!Profile::GetProfileValue(Lobby.LobbyOwner, n"FriendsPassInfoShown", ShownValue)
				|| ShownValue != "True" || CVar_AlwaysShowFriendsPassPopup.GetInt() != 0)
			{
				ShowFriendsPassPopup();
				Profile::SetProfileValue(Lobby.LobbyOwner, n"FriendsPassInfoShown", "True");
			}
		}
	}

	UFUNCTION()
	void CancelHostChoice()
	{
		Lobby::Menu_LeaveLobby();
	}

	UFUNCTION()
	void CancelInviteChoice()
	{
		FriendListState = EFriendListState::None;
		UpdateFriendList();
	}

	void BindMemberEvents(ULobbyMemberWidget MemberWidget)
	{
		if (MemberWidget == nullptr)
			return;
		MemberWidget.OnClicked.AddUFunction(this, n"OnMemberClicked");
	}

	UFUNCTION()
	private void OnMemberClicked(ULobbyMemberWidget Member)
	{
		UHazePlayerIdentity KeyIdentity = Online::GetLocalIdentityAssociatedWithInputDevice(-1);
		UHazePlayerIdentity KeyIdentityInLobby = Lobby.GetIdentityForInput(-1);

		if (Lobby.NumIdentitiesInLobby() < 2
			&& Lobby.Network == EHazeLobbyNetwork::Local
			&& PendingJoinIdentity == nullptr
			&& (KeyIdentityInLobby == nullptr || KeyIdentityInLobby.IsSecondaryController(-1))
		)
		{
			// Join a local lobby
			PendingJoinIdentity = KeyIdentity;
			if (KeyIdentityInLobby == nullptr)
				KeyIdentity.OnInputTakenFromControllerId(-1, true);
			ProceedPendingJoin();
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_SetContinueChapter(FHazeChapterGroup ChapterGroup, FHazeChapter Chapter) {}

	UFUNCTION(BlueprintPure)
	bool CanInvitePlayer()
	{
		if (Lobby == nullptr)
			return false;
		return Lobby.Network == EHazeLobbyNetwork::Host
			&& Lobby.NumIdentitiesInLobby() < 2
			&& (Online::HasInvitePrompt() || bIsPC);
	}

	UFUNCTION(BlueprintPure)
	bool CanStartSelectedChapter()
	{
		if (Lobby == nullptr)
			return false;
		if (!Lobby.LobbyOwner.IsLocal())
			return true;

		switch (Lobby.StartType)
		{
			case EHazeLobbyStartType::NewGame:
				return true;
			case EHazeLobbyStartType::ChapterSelect:
			case EHazeLobbyStartType::Continue:
			case EHazeLobbyStartType::PickMinigame:
				return Save::IsContinueStartable(Lobby.StartChapter, Lobby.StartProgressPoint);
		}

		return true;
	}

	UFUNCTION(BlueprintPure)
	bool HasMinigamesUnlocked()
	{
		return MinigamePicker.bHasUnlockedMinigames;
	}

	UFUNCTION()
	void BrowseStartType(int BrowseDirection, bool bWrap = false)
	{
		EHazeLobbyStartType NewStartType = Lobby.StartType;
		while (true)
		{
			auto CheckingStartType = NewStartType;
			if (BrowseDirection < 0)
			{
				switch (NewStartType)
				{
					case EHazeLobbyStartType::NewGame:
						if (bWrap)
							NewStartType = EHazeLobbyStartType::PickMinigame;
					break;
					case EHazeLobbyStartType::Continue:
						NewStartType = EHazeLobbyStartType::NewGame;
					break;
					case EHazeLobbyStartType::ChapterSelect:
						NewStartType = EHazeLobbyStartType::Continue;
					break;
					case EHazeLobbyStartType::PickMinigame:
						NewStartType = EHazeLobbyStartType::ChapterSelect;
					break;
				}
			}
			else
			{
				switch (NewStartType)
				{
					case EHazeLobbyStartType::NewGame:
						NewStartType = EHazeLobbyStartType::Continue;
					break;
					case EHazeLobbyStartType::Continue:
						NewStartType = EHazeLobbyStartType::ChapterSelect;
					break;
					case EHazeLobbyStartType::ChapterSelect:
						NewStartType = EHazeLobbyStartType::PickMinigame;
					break;
					case EHazeLobbyStartType::PickMinigame:
						if (bWrap)
							NewStartType = EHazeLobbyStartType::NewGame;
					break;
				}
			}

			bool bIsStartTypeValid = true;
			switch (NewStartType)
			{
				case EHazeLobbyStartType::Continue:
					if (!bHasContinue)
						bIsStartTypeValid = false;
				break;
				case EHazeLobbyStartType::ChapterSelect:
					if (!bHasContinue)
						bIsStartTypeValid = false;
				break;
				case EHazeLobbyStartType::PickMinigame:
					if (!MinigamePicker.bHasUnlockedMinigames)
						bIsStartTypeValid = false;
				break;
			}

			if (NewStartType == Lobby.StartType)
				return;

			if (bIsStartTypeValid)
			{
				SetLobbyStartType(NewStartType);				
				return;
			}

			if (NewStartType == CheckingStartType)
				return;
		}
	}

	UFUNCTION()
	void SetLobbyStartType(EHazeLobbyStartType StartType)
	{
		if (!Lobby.LobbyOwner.IsLocal())
			return;

		switch (StartType)
		{
			case EHazeLobbyStartType::NewGame:
			{
				Lobby::Menu_LobbySelectStart(
					EHazeLobbyStartType::NewGame,
					ChapterDatabase.GetInitialChapter(),
					ChapterDatabase.GetInitialChapter());
			}
			break;
			case EHazeLobbyStartType::ChapterSelect:
			{
				if (HasContinueSave())
				{
					Lobby::Menu_LobbySelectStart(
						EHazeLobbyStartType::ChapterSelect,
						ChapterPicker.SelectedChapter.ProgressPoint,
						ChapterPicker.SelectedChapter.ProgressPoint);
				}
			}
			break;
			case EHazeLobbyStartType::Continue:
			{
				if (HasContinueSave())
				{
					Lobby::Menu_LobbySelectStart(
						EHazeLobbyStartType::Continue,
						ContinueChapter,
						ContinuePoint);
				}
			}
			break;
			case EHazeLobbyStartType::PickMinigame:
			{
				if (MinigamePicker.bHasUnlockedMinigames)
				{
					Lobby::Menu_LobbySelectStart(
						EHazeLobbyStartType::PickMinigame,
						MinigamePicker.GetSelectedMinigame(),
						MinigamePicker.GetSelectedMinigame());
				}
			}
			break;
		}
	}

	UFUNCTION()
	void InviteFriend()
	{
		if (bIsPC && Online::GetGameServerMode() != EHazeGameServerMode::UseSteamGameServers)
		{
			PromptForTypeOfInvite();
		}
		else
		{
			if (CanInvitePlayer())
				Online::PromptForInvite();
		}
	}

	void StartLobbyHost()
	{
		Online::SetLobbyJoinable(true);
	}

	void PromptForTypeOfInvite()
	{
		FriendListState = EFriendListState::InviteChoice;
		UpdateFriendList();

		GetAudioManager().UI_PopupMessageOpen();

		if (bIsSteam)
			Widget::SetAllPlayerUIFocus(SendInviteChoiceButton_Steam);
		else
			Widget::SetAllPlayerUIFocus(SendInviteChoiceButton_Origin);
	}

	UFUNCTION()
	void OnSendInviteChoice()
	{
		Online::PromptForInvite();
		FriendListState = EFriendListState::None;
		UpdateFriendList();
		StartLobbyHost();
	}

	UFUNCTION()
	void OnManageFriendsChoice()
	{
		FriendListState = EFriendListState::FriendList;
		UpdateFriendList();

		RefreshFriends();
		RefreshTimer = 0.5;

		GetAudioManager().UI_OnSelectionConfirmed();

		bAwaitingFocus = true;

		EHazePlayerControllerType Type = Lobby::GetMostLikelyControllerType();
		if (Type == EHazePlayerControllerType::Keyboard)
			AwaitingFocusCause = EFocusCause::Mouse;
		else
			AwaitingFocusCause = EFocusCause::Navigation;
	}

	void OpenFriendAction(UHazeOnlineFriend Friend)
	{
		if (FriendListState == EFriendListState::BlockList)
			FriendListState = EFriendListState::BlockListAction;
		else if (FriendListState == EFriendListState::FriendSearch)
			FriendListState = EFriendListState::FriendSearchAction;
		else
			FriendListState = EFriendListState::FriendAction;
		ActionFriend = Friend;
		UpdateFriendList();

		if (FriendAction_JoinOnlineLobby.Visibility == ESlateVisibility::Visible)
			Widget::SetAllPlayerUIFocus(FriendAction_JoinOnlineLobby);
		else if (FriendAction_InviteToGame.Visibility == ESlateVisibility::Visible)
			Widget::SetAllPlayerUIFocus(FriendAction_InviteToGame);
		else if (FriendAction_InviteToGame_Steam.Visibility == ESlateVisibility::Visible)
			Widget::SetAllPlayerUIFocus(FriendAction_InviteToGame_Steam);
		else if (FriendAction_InviteToGame_EA.Visibility == ESlateVisibility::Visible)
			Widget::SetAllPlayerUIFocus(FriendAction_InviteToGame_EA);
		else if (FriendAction_AcceptFriendRequest.Visibility == ESlateVisibility::Visible)
			Widget::SetAllPlayerUIFocus(FriendAction_AcceptFriendRequest);
		else if (FriendAction_DeclineFriendRequest.Visibility == ESlateVisibility::Visible)
			Widget::SetAllPlayerUIFocus(FriendAction_DeclineFriendRequest);
		else if (FriendAction_CancelFriendRequest.Visibility == ESlateVisibility::Visible)
			Widget::SetAllPlayerUIFocus(FriendAction_CancelFriendRequest);
		else if (FriendAction_Unblock.Visibility == ESlateVisibility::Visible)
			Widget::SetAllPlayerUIFocus(FriendAction_Unblock);
		else if (FriendAction_Block.Visibility == ESlateVisibility::Visible)
			Widget::SetAllPlayerUIFocus(FriendAction_Block);
		else if (FriendAction_Unfriend.Visibility == ESlateVisibility::Visible)
			Widget::SetAllPlayerUIFocus(FriendAction_Unfriend);
		else if (FriendAction_RequestFriend.Visibility == ESlateVisibility::Visible)
			Widget::SetAllPlayerUIFocus(FriendAction_RequestFriend);
		else
			Widget::SetAllPlayerUIFocus(FriendAction_Close);
	}

	void OpenFriendSearch()
	{
		if (ShouldShowSearchInputBox())
		{
			OnSearchPromptInput("");
		}
		else
		{
			Online::PromptTextInput(
				NSLOCTEXT("EAOnline", "SearchFriendPromptTitle", "Search for Friend by EA Account"),
				NSLOCTEXT("EAOnline", "SearchFriendPromptDescription", "Enter the EA account name of a friend"),
				FHazeOnOnlineSystemTextInput(this, n"OnSearchPromptInput")
			);
		}
	}

	UFUNCTION()
	void OnSearchPromptInput(FString SearchText)
	{
		Online::StartFriendSearch(SearchText);
		SearchInputBox.SetText(FText::FromString(SearchText));

		FriendListState = EFriendListState::FriendSearch;
		UpdateFriendList();

		RefreshSearch();
		RefreshTimer = 0.4;

		if (ShouldShowSearchInputBox())
			Widget::SetAllPlayerUIFocus(SearchInputBox);
		else
			Widget::SetAllPlayerUIFocus(this);
	}

	UFUNCTION()
	private void OnSearchTextChanged(const FText&in Text)
	{
		if (FriendListState == EFriendListState::FriendSearch)
		{
			Online::StartFriendSearch(Text.ToString());
			RefreshSearch();
			RefreshTimer = 0.4;
		}
	}

	UFUNCTION()
	void CloseSearch()
	{
		Online::StopFriendSearch();
		FriendListState = EFriendListState::FriendList;
		UpdateFriendList();
		Widget::SetAllPlayerUIFocus(this);
		GetAudioManager().UI_OnSelectionCancel();
	}

	UFUNCTION()
	void OpenBlockList()
	{
		FriendListState = EFriendListState::BlockList;
		UpdateFriendList();

		RefreshBlockList();
		RefreshTimer = 0.4;

		Widget::SetAllPlayerUIFocus(this);
	}

	UFUNCTION()
	void CloseBlockList()
	{
		FriendListState = EFriendListState::FriendList;
		UpdateFriendList();
		Widget::SetAllPlayerUIFocus(this);
		GetAudioManager().UI_OnSelectionCancel();
	}

	UFUNCTION()
	void OnFriendAction_InviteToGame()
	{
		if (ActionFriend == nullptr)
			return;

		Online::SendGameInviteToFriend(ActionFriend, true);
		CloseFriendAction();
		GetAudioManager().UI_OnSelectionConfirmed();
	}
	
	UFUNCTION()
	void OnFriendAction_InviteToGame_Steam()
	{
		if (ActionFriend == nullptr)
			return;

		Online::SendGameInviteToFriend(ActionFriend, true);
		CloseFriendAction();
		GetAudioManager().UI_OnSelectionConfirmed();
	}

	UFUNCTION()
	void OnFriendAction_InviteToGame_EA()
	{
		if (ActionFriend == nullptr)
			return;

		Online::SendGameInviteToFriend(ActionFriend, false);
		CloseFriendAction();
		GetAudioManager().UI_OnSelectionConfirmed();
	}

	UFUNCTION()
	void OnFriendAction_JoinOnlineLobby()
	{
		if (ActionFriend == nullptr)
			return;

		Online::JoinFriendLobby(ActionFriend);
		CloseFriendAction();
		GetAudioManager().UI_OnSelectionConfirmed();
	}
	UFUNCTION()
	void OnFriendAction_AcceptFriendRequest()
	{
		if (ActionFriend == nullptr)
			return;

		Online::RespondToFriendRequest(ActionFriend, true);
		CloseFriendAction();
		GetAudioManager().UI_OnSelectionConfirmed();
	}
	UFUNCTION()
	void OnFriendAction_DeclineFriendRequest()
	{
		if (ActionFriend == nullptr)
			return;

		Online::RespondToFriendRequest(ActionFriend, false);
		CloseFriendAction();
		GetAudioManager().UI_OnSelectionConfirmed();
	}
	UFUNCTION()
	void OnFriendAction_CancelFriendRequest()
	{
		if (ActionFriend == nullptr)
			return;

		Online::CancelFriendRequest(ActionFriend);
		CloseFriendAction();
		GetAudioManager().UI_OnSelectionConfirmed();
	}
	UFUNCTION()
	void OnFriendAction_Unblock()
	{
		if (ActionFriend == nullptr)
			return;

		Online::SetFriendBlocked(ActionFriend, false);
		CloseFriendAction();
		GetAudioManager().UI_OnSelectionConfirmed();
	}
	UFUNCTION()
	void OnFriendAction_Block()
	{
		if (ActionFriend == nullptr)
			return;

		FMessageDialog Dialog;
		Dialog.Type = EMessageDialogType::YesNo;
		Dialog.Message = NSLOCTEXT("LobbyFriend", "BlockQuestion", "Add {0} to the block list?");
		Dialog.Message = FText::FromString(Dialog.Message.ToString().Replace("{0}", ActionFriend.Nickname.ToString()));
		Dialog.ConfirmText = NSLOCTEXT("LobbyFriend", "BlockFriend", "Block");
		Dialog.CancelText = NSLOCTEXT("Lobby", "CancelLeaveLobby", "Cancel");
		Dialog.OnClosed.BindUFunction(this, n"Respond_Block");

		GetAudioManager().UI_PopupMessageOpen();
		ShowPopupMessage(Dialog);
	}

	UFUNCTION()
	void Respond_Block(EMessageDialogResponse Response)
	{
		if (Response == EMessageDialogResponse::Yes)
		{
			if (ActionFriend != nullptr)
				Online::SetFriendBlocked(ActionFriend, true);
			GetAudioManager().UI_OnSelectionConfirmed();
		}
		else
		{
			GetAudioManager().UI_OnSelectionCancel();
		}

		CloseFriendAction();
	}

	UFUNCTION()
	void OnFriendAction_Unfriend()
	{
		if (ActionFriend == nullptr)
			return;

		FMessageDialog Dialog;
		Dialog.Type = EMessageDialogType::YesNo;
		Dialog.Message = NSLOCTEXT("LobbyFriend", "UnfriendQuestion", "Remove {0} from EA friends list?");
		Dialog.Message = FText::FromString(Dialog.Message.ToString().Replace("{0}", ActionFriend.Nickname.ToString()));
		Dialog.ConfirmText = NSLOCTEXT("LobbyFriend", "RemoveFriend", "Unfriend");
		Dialog.CancelText = NSLOCTEXT("Lobby", "CancelLeaveLobby", "Cancel");
		Dialog.OnClosed.BindUFunction(this, n"Respond_Unfriend");

		GetAudioManager().UI_PopupMessageOpen();
		ShowPopupMessage(Dialog);
	}
	UFUNCTION()
	void Respond_Unfriend(EMessageDialogResponse Response)
	{
		if (Response == EMessageDialogResponse::Yes)
		{
			if (ActionFriend != nullptr)
				Online::RemoveFriend(ActionFriend);

			GetAudioManager().UI_OnSelectionConfirmed();
		}
		else
		{
			GetAudioManager().UI_OnSelectionCancel();
		}

		CloseFriendAction();
	}

	UFUNCTION()
	void OnFriendAction_RequestFriend()
	{
		if (ActionFriend == nullptr)
			return;

		Online::SendFriendRequest(ActionFriend);

		FriendListState = EFriendListState::FriendList;
		ActionFriend = nullptr;
		UpdateFriendList();
		GetAudioManager().UI_OnSelectionConfirmed();
	}
	void CloseFriendAction()
	{
		if (FriendListState == EFriendListState::BlockListAction)
			FriendListState = EFriendListState::BlockList;
		else if (FriendListState == EFriendListState::FriendSearchAction)
			FriendListState = EFriendListState::FriendSearch;
		else
			FriendListState = EFriendListState::FriendList;
		ActionFriend = nullptr;
		UpdateFriendList();
		Widget::SetAllPlayerUIFocus(this);
	}
	UFUNCTION()
	void OnFriendAction_Close()
	{
		CloseFriendAction();
		GetAudioManager().UI_OnSelectionCancel();
	}

	UFUNCTION()
	void ProceedGame()
	{
		if (CanStartSelectedChapter())
			Lobby::Menu_LobbySetState(EHazeLobbyState::CharacterSelect);
	}

	UFUNCTION(BlueprintOverride)
	UWidget OnCustomNavigation(FGeometry Geometry, FNavigationEvent Event, EUINavigationRule& OutRule)
	{
		if (Lobby == nullptr || Lobby.HasGameStarted())
			return nullptr;

		if (bInFriendsPassPopup)
			return nullptr;

		if (FriendListState != EFriendListState::None)
			return nullptr;

		// We respond to navigation for chapter select,
		// so analog stick can be used for switching chapters.
		// We don't use the simulated buttons for the left stick,
		// because those are not nicely deadzoned.

		if (Lobby.LobbyOwner.TakesInputFromControllerId(Event.ControllerId))
		{
			if (Lobby.StartType == EHazeLobbyStartType::ChapterSelect)
			{
				if (Event.NavigationType == EUINavigation::Left)
				{
					ChapterPicker.NavigateGroup(-1);
				}
				else if (Event.NavigationType == EUINavigation::Right)
				{
					ChapterPicker.NavigateGroup(+1);
				}
				else if (Event.NavigationType == EUINavigation::Up)
				{
					ChapterPicker.NavigateChapter(-1);
				}
				else if (Event.NavigationType == EUINavigation::Down)
				{
					ChapterPicker.NavigateChapter(+1);
				}
			}
			else if (Lobby.StartType == EHazeLobbyStartType::PickMinigame)
			{
				if (Event.NavigationType == EUINavigation::Up)
				{
					MinigamePicker.BrowseMinigame(-1);
				}
				else if (Event.NavigationType == EUINavigation::Down)
				{
					MinigamePicker.BrowseMinigame(+1);
				}
			}
		}

		return nullptr;
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnAnalogValueChanged(FGeometry MyGeometry, FAnalogInputEvent Event)
	{
		if (Lobby == nullptr || Lobby.HasGameStarted())
			return FEventReply::Unhandled();

		if (Lobby.StartType == EHazeLobbyStartType::PickMinigame)
		{
			if (Event.GetKey() == EKeys::Gamepad_RightY && FMath::Abs(Event.AnalogValue) > 0.4f)
			{
				MinigamePicker.Scroll(Event.AnalogValue * -400.f * Time::UndilatedWorldDeltaSeconds);
				return FEventReply::Handled();
			}
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry Geom, FKeyEvent Event)
	{
		if (Lobby == nullptr || Lobby.HasGameStarted())
			return FEventReply::Unhandled();
		if (KCodeHandler.AddInput(this, Event.Key))
			return FEventReply::Handled();
		if (Event.IsRepeat())
			return FEventReply::Unhandled();
		if (!bIsActive)
			return FEventReply::Unhandled();

		UHazePlayerIdentity KeyIdentity = Online::GetLocalIdentityAssociatedWithInputDevice(Event.ControllerId);
		UHazePlayerIdentity KeyIdentityInLobby = Lobby.GetIdentityForInput(Event.ControllerId);

		if (FriendListState != EFriendListState::None)
		{
			if (Event.Key == EKeys::Escape || Event.Key == EKeys::Virtual_Back)
			{
				if (FriendListState == EFriendListState::InviteChoice)
				{
					CancelInviteChoice();

					Widget::SetAllPlayerUIFocus(this);
					GetAudioManager().UI_OnSelectionCancel();

					return FEventReply::Handled();
				}
				else if (FriendListState == EFriendListState::HostChoice)
				{
					Lobby::Menu_LeaveLobby();

					GetAudioManager().UI_OnSelectionCancel();
					return FEventReply::Handled();
				}
				else if (FriendListState == EFriendListState::FriendList)
				{
					FriendListState = EFriendListState::None;
					UpdateFriendList();
					Widget::SetAllPlayerUIFocus(this);
					GetAudioManager().UI_OnSelectionCancel();

					return FEventReply::Handled();
				}
				else if (FriendListState == EFriendListState::FriendSearchAction)
				{
					FriendListState = EFriendListState::FriendSearch;
					UpdateFriendList();
					Widget::SetAllPlayerUIFocus(this);
					GetAudioManager().UI_OnSelectionCancel();

					return FEventReply::Handled();
				}
				else if (FriendListState == EFriendListState::BlockListAction)
				{
					FriendListState = EFriendListState::BlockList;
					UpdateFriendList();
					Widget::SetAllPlayerUIFocus(this);
					GetAudioManager().UI_OnSelectionCancel();

					return FEventReply::Handled();
				}
				else
				{
					FriendListState = EFriendListState::FriendList;
					Online::StopFriendSearch();
					UpdateFriendList();
					Widget::SetAllPlayerUIFocus(this);
					GetAudioManager().UI_OnSelectionCancel();

					return FEventReply::Handled();
				}
			}
			else if (Event.Key == EKeys::Gamepad_FaceButton_Top)
			{
				if (FriendListState == EFriendListState::FriendList)
				{
					OpenFriendSearch();
					GetAudioManager().UI_PopupMessageOpen();
					return FEventReply::Handled();
				}
			}
			else if (Event.Key == EKeys::Gamepad_LeftShoulder)
			{
				if (FriendListState == EFriendListState::FriendList)
				{
					OpenBlockList();
					GetAudioManager().UI_PopupMessageOpen();
					return FEventReply::Handled();
				}
			}

			return Super::OnKeyDown(Geom, Event);
		}

		// Deal with input to the friends pass popup
		if (bInFriendsPassPopup)
		{
			if (Lobby.LobbyOwner.TakesInputFromControllerId(Event.ControllerId))
			{
				if (Event.Key == EKeys::Enter || Event.Key == EKeys::Virtual_Accept
					|| Event.Key == EKeys::Escape || Event.Key == EKeys::Virtual_Back)
				{
					HideFriendsPassPopup();
					return FEventReply::Handled();
				}
				else if (Event.Key == EKeys::F1 || Event.Key == EKeys::Gamepad_FaceButton_Left)
				{
					ShowFriendsPassMoreInfo();
					return FEventReply::Handled();
				}
			}

			return Super::OnKeyDown(Geom, Event);
		}
		else
		{
			if (Event.Key == EKeys::F2 || Event.Key == EKeys::Gamepad_FaceButton_Left)
			{
				if (ShouldShowFriendsPassInfo())
				{
					ShowFriendsPassPopup();
					return FEventReply::Handled();
				}
			}
		}

		// Host can prompt to invite a player
		if (Event.Key == EKeys::Gamepad_FaceButton_Top
			|| Event.Key == EKeys::Y
			|| Event.Key == EKeys::F1)
		{
			InviteFriend();
			return FEventReply::Handled();
		}

		if (Lobby.NumIdentitiesInLobby() < 2
			&& Lobby.Network == EHazeLobbyNetwork::Local
			&& PendingJoinIdentity == nullptr
			&& (KeyIdentityInLobby == nullptr || KeyIdentityInLobby.IsSecondaryController(Event.ControllerId))
		)
		{
			if (Event.Key == EKeys::Virtual_Accept || Event.Key == EKeys::Enter)
			{
				// Join a local lobby
				PendingJoinIdentity = KeyIdentity;
				if (KeyIdentityInLobby == nullptr)
					KeyIdentity.OnInputTakenFromControllerId(Event.ControllerId, true);
				ProceedPendingJoin();
				return FEventReply::Handled();
			}
		}

		if (Event.Key == EKeys::Escape || Event.Key == EKeys::Virtual_Back)
		{
			// Leave lobby for local joined player
			if (KeyIdentityInLobby != nullptr && CanIdentityLeaveLobby(KeyIdentityInLobby) && Lobby.Network == EHazeLobbyNetwork::Local)
			{
				Lobby::Menu_RemoveLocalPlayerFromLobby(KeyIdentityInLobby);
				return FEventReply::Handled();
			}

			// Leave lobby for owner of menu, could be leaving a joined online lobby or a local lobby
			if (MainMenu.OwnerIdentity.TakesInputFromControllerId(Event.ControllerId))
			{
				LeaveLobby();
				return FEventReply::Handled();
			}
		}

		// Switch game start type
		if (Event.Key == EKeys::Gamepad_LeftShoulder)
		{
			if (Lobby.LobbyOwner.TakesInputFromControllerId(Event.ControllerId))
			{
				BrowseStartType(-1, bWrap = true);
				NarrateFullMenu();
				return FEventReply::Handled();
			}
		}

		if (Event.Key == EKeys::Gamepad_RightShoulder
			|| Event.Key == EKeys::Tab)
		{
			if (Lobby.LobbyOwner.TakesInputFromControllerId(Event.ControllerId))
			{
				BrowseStartType(+1, bWrap = true);
				NarrateFullMenu();
				return FEventReply::Handled();
			}
		}

		// Proceed to character select from chapter select
		if (Event.Key == EKeys::Enter
			|| Event.Key == EKeys::Virtual_Accept)
		{
			if (Lobby.LobbyOwner.TakesInputFromControllerId(Event.ControllerId)
				&& NumIdentitiesInLobby() >= 2)
			{
				ProceedGame();
				GetAudioManager().UI_ProceedToCharacterSelect();
				return FEventReply::Handled();
			}
		}
		
		return Super::OnKeyDown(Geom, Event);
	}

	void ProceedPendingJoin()
	{
		if (Lobby.NumIdentitiesInLobby() >= 2)
		{
			PendingJoinIdentity = nullptr;
			return;
		}

		// Make sure we're signed in before we can join
		if (!Online::IsIdentitySignedIn(PendingJoinIdentity) || Lobby.IsMember(PendingJoinIdentity))
		{
			auto SignInWithIdentity = PendingJoinIdentity;
			PendingJoinIdentity = nullptr;
			bIsPendingSignIn = true;
			Online::PromptIdentitySignIn(SignInWithIdentity, FHazeOnOnlineIdentitySignedIn(this, n"OnJoinIdentitySignedIn"));
			return;
		}

		// Make sure the profile is loaded before we can join
		if (!Profile::IsProfileLoaded(PendingJoinIdentity))
		{
			Profile::LoadProfile(PendingJoinIdentity, FHazeOnProfileLoaded(this, n"OnJoinIdentityProfileLoaded"));
			return;
		}

		// All steps completed!
		auto FinishedIdentity = PendingJoinIdentity;
		PendingJoinIdentity = nullptr;
		EngagementGraceTimer = 1.f;
		Lobby::Menu_AddLocalIdentityToLobby(FinishedIdentity);
	}

	UFUNCTION()
	void OnJoinIdentityProfileLoaded(UHazePlayerIdentity Identity)
	{
		ProceedPendingJoin();
	}

	UFUNCTION()
	void OnJoinIdentitySignedIn(UHazePlayerIdentity Identity, bool bSuccess)
	{
		bIsPendingSignIn = false;
		if (bSuccess && PendingJoinIdentity == nullptr && !Lobby.IsMember(Identity))
		{
			PendingJoinIdentity = Identity;
			ProceedPendingJoin();
		}
	}

	UFUNCTION(BlueprintPure)
	bool HasContinueSave()
	{
		return bHasContinue;
	}

	UFUNCTION(BlueprintPure)
	bool CanProceedToCharacterSelect()
	{
		if (Lobby == nullptr)
			return false;
		if (!CanStartSelectedChapter())
			return false;
		return Lobby.LobbyOwner.IsLocal()
			&& NumIdentitiesInLobby() >= 2;
	}

	UFUNCTION(BlueprintPure)
	bool IsJoinInProgress()
	{
		return PendingJoinIdentity != nullptr || bIsPendingSignIn;
	}

	bool CanIdentityLeaveLobby(UHazePlayerIdentity Identity)
	{
		if (Identity == Lobby.LobbyMembers[1].Identity)
		{
			// Secondary player can always leave
			return true;
		}

		if (Identity == Lobby.LobbyMembers[0].Identity)
		{
			// Primary player can only leave on desktop platforms
			if (!Game::IsConsoleBuild())
				return true;
			else
				return false;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry Geom, float Timer)
	{
		Super::Tick(Geom, Timer);

		if (Lobby == nullptr)
			return;
		if (!bIsActive)
			return;

		// Proceed to character select if the lobby state has changed
		if (Lobby.LobbyState == EHazeLobbyState::CharacterSelect)
		{
			MainMenu.ProceedToCharacterSelect();
			return;
		}

		// If the secondary identity is disengaged, remove it from the lobby
		EngagementGraceTimer -= Timer;
		if (EngagementGraceTimer <= 0.f)
		{
			for (auto& Member : Lobby.LobbyMembers)
			{
				if (Member.Identity != nullptr && Member.Identity != Online::PrimaryIdentity)
				{
					if (Member.Identity.Engagement != EHazeIdentityEngagement::Engaged)
					{
						GetAudioManager().UI_OnSelectionCancel();
						Lobby::Menu_RemoveLocalPlayerFromLobby(Member.Identity);
					}
				}
			}
		}

		// Inform BP if the start type has changed
		if (CurrentStartType != Lobby.StartType)
		{
			BP_StartTypeChanged(CurrentStartType, Lobby.StartType);			
			CurrentStartType = Lobby.StartType;

			if(bHasTickedForSound)
				GetAudioManager().UI_StartModeUpdated();
		}

		// Inform chapter picker if chapter has changed in network
		if (!Lobby.LobbyOwner.IsLocal())
		{
			if (CurrentStartType == EHazeLobbyStartType::ChapterSelect)
			{
				if (Lobby.StartChapter.InLevel != ChapterPicker.SelectedChapter.ProgressPoint.InLevel
					|| Lobby.StartChapter.Name != ChapterPicker.SelectedChapter.ProgressPoint.Name)
				{
					ChapterPicker.SelectChapter(Lobby.StartChapter);
				}
			}
			else if (CurrentStartType == EHazeLobbyStartType::PickMinigame)
			{
				if (Lobby.StartChapter.InLevel != MinigamePicker.SelectedMinigame.InLevel
					|| Lobby.StartChapter.Name != MinigamePicker.SelectedMinigame.Name)
				{
					MinigamePicker.SelectMinigame(Lobby.StartChapter, false);
				}
			}
			else if (CurrentStartType == EHazeLobbyStartType::Continue)
			{
				if (Lobby.StartChapter.InLevel != ContinueChapter.InLevel
					|| Lobby.StartChapter.Name != ContinueChapter.Name)
				{
					ContinueChapter = Lobby.StartChapter;
					FHazeChapter Chapter = ChapterDatabase.GetChapterByProgressPoint(ContinueChapter);
					FHazeChapterGroup Group = ChapterDatabase.GetChapterGroup(Chapter);
					BP_SetContinueChapter(Group, Chapter);
				}

			}
		}

		// Update busy state for pending profile loads
		auto PlayerTwoWidget = GetLobbyJoinerWidget();
		if (PlayerTwoWidget != nullptr)
			PlayerTwoWidget.bIsBusy = IsJoinInProgress();

		if (bNarrateNextTick)
		{
			bNarrateNextTick = false;
			InternalNarrateFullMenu();
		}

		const int NumPlayers = Lobby.NumIdentitiesInLobby();
		if(bHasTickedForSound)	
		{
			if(PlayersInLobby < NumPlayers)
				GetAudioManager().UI_OnPlayerJoin();
			else if(PlayersInLobby > NumPlayers)
				GetAudioManager().UI_OnPlayerLeave();
		}	

		bHasTickedForSound = true;
		PlayersInLobby = NumPlayers;		
		UpdateFriendList(Timer);
		UpdateFocus();
	}

	void UpdateFriendList(float DeltaTime = 0.f)
	{
		InviteChoicePopup.Visibility = (FriendListState == EFriendListState::InviteChoice) ? ESlateVisibility::Visible : ESlateVisibility::Collapsed;
		HostChoicePopup.Visibility = (FriendListState == EFriendListState::HostChoice) ? ESlateVisibility::Visible : ESlateVisibility::Collapsed;
		FriendListPopup.Visibility = (FriendListState != EFriendListState::None && FriendListState != EFriendListState::InviteChoice && FriendListState != EFriendListState::HostChoice) ? ESlateVisibility::Visible : ESlateVisibility::Collapsed;
		FriendActionPopup.Visibility = (FriendListState == EFriendListState::FriendAction || FriendListState == EFriendListState::FriendSearchAction || FriendListState == EFriendListState::BlockListAction) ? ESlateVisibility::Visible : ESlateVisibility::Collapsed;
		FriendSearchPopup.Visibility = (FriendListState == EFriendListState::FriendSearch || FriendListState == EFriendListState::FriendSearchAction) ? ESlateVisibility::Visible : ESlateVisibility::Collapsed;
		BlockListPopup.Visibility = (FriendListState == EFriendListState::BlockList || FriendListState == EFriendListState::BlockListAction) ? ESlateVisibility::Visible : ESlateVisibility::Collapsed;

		if (FriendListState == EFriendListState::InviteChoice)
		{
			if (ManageEAFriendsButton.HasAnyUserFocus())
				bWasFriendsChoiceFocused = true;
			else if (SendInviteChoiceButton_Steam.HasAnyUserFocus() || SendInviteChoiceButton_Origin.HasAnyUserFocus())
				bWasFriendsChoiceFocused = false;
		}

		if (FriendListState == EFriendListState::FriendAction || FriendListState == EFriendListState::FriendSearchAction || FriendListState == EFriendListState::BlockListAction)
		{
			UpdateFriendActions();
		}

		if (!IsMessageDialogShown())
			Widget::SetAllPlayerUIFocusBeneathParent(this);

		RefreshTimer -= DeltaTime;
		if (RefreshTimer < 0.0)
		{
			if (FriendListState != EFriendListState::None && FriendListState != EFriendListState::InviteChoice && FriendListState != EFriendListState::HostChoice)
				RefreshFriends();
			if (FriendListState == EFriendListState::FriendSearch)
				RefreshSearch();
			if (FriendListState == EFriendListState::BlockList)
				RefreshBlockList();

			RefreshTimer = 1.0;
		}

		if (FriendListState == EFriendListState::FriendList)
		{
			FText Username = FText::FromString(Online::GetEAUsername());
			EAAccountNameText.SetText(Username);

			auto SelectedFriend = FriendList.GetSelectedItem();
			if (SelectedFriend == nullptr && FriendObjects.Num() != 0)
			{
				FriendList.SetSelectedIndex(0);
				FriendList.ScrollIndexIntoView(0);

				auto SelectedWidget = FriendList.GetEntryWidgetForItemIndex(0);
				if (SelectedWidget != nullptr)
					Widget::SetAllPlayerUIFocus(SelectedWidget);
			}
		}

		if (FriendListState == EFriendListState::FriendSearch)
		{
			if (SearchList.HasAnyUserFocus())
			{
				SearchList.SetSelectedIndex(0);
				SearchList.ScrollIndexIntoView(0);

				auto SelectedWidget = SearchList.GetEntryWidgetForItemIndex(0);
				if (SelectedWidget != nullptr)
					Widget::SetAllPlayerUIFocus(SelectedWidget);
			}

			auto SelectedFriend = SearchList.GetSelectedItem();
			if (SelectedFriend == nullptr && SearchObjects.Num() != 0)
			{
				SearchList.SetSelectedIndex(0);
				SearchList.ScrollIndexIntoView(0);

				auto SelectedWidget = SearchList.GetEntryWidgetForItemIndex(0);
				if (SelectedWidget != nullptr)
					Widget::SetAllPlayerUIFocus(SelectedWidget);
			}
		}

		if (FriendListState == EFriendListState::BlockList)
		{
			auto SelectedFriend = BlockList.GetSelectedItem();
			if (SelectedFriend == nullptr && BlockListObjects.Num() != 0)
			{
				BlockList.SetSelectedIndex(0);
				BlockList.ScrollIndexIntoView(0);

				auto SelectedWidget = BlockList.GetEntryWidgetForItemIndex(0);
				if (SelectedWidget != nullptr)
					Widget::SetAllPlayerUIFocus(SelectedWidget);
			}
		}
	}

	void UpdateFriendActions()
	{
		if (ActionFriend == nullptr)
			return;

		FriendActionName.Text = ActionFriend.Nickname;

		if (ActionFriend.bIsInJoinableLobby && ActionFriend.bIsFriend)
			FriendAction_JoinOnlineLobby.Visibility = ESlateVisibility::Visible;
		else
			FriendAction_JoinOnlineLobby.Visibility = ESlateVisibility::Collapsed;

		if (ActionFriend.bIsFriend)
		{
			if (bIsPC)
			{
				if (ActionFriend.FirstPartyType == EHazeOnlineFirstPartyType::Steam)
				{
					FriendAction_InviteToGame_Steam.Visibility = ESlateVisibility::Visible;
					FriendAction_InviteToGame_EA.Visibility = ESlateVisibility::Visible;
					FriendAction_InviteToGame.Visibility = ESlateVisibility::Collapsed;
				}
				else
				{
					FriendAction_InviteToGame_Steam.Visibility = ESlateVisibility::Collapsed;
					FriendAction_InviteToGame_EA.Visibility = ESlateVisibility::Visible;
					FriendAction_InviteToGame.Visibility = ESlateVisibility::Collapsed;
				}
			}
			else
			{
				FriendAction_InviteToGame.Visibility = ESlateVisibility::Visible;
			}
		}
		else
		{
			FriendAction_InviteToGame.Visibility = ESlateVisibility::Collapsed;
			FriendAction_InviteToGame_EA.Visibility = ESlateVisibility::Collapsed;
			FriendAction_InviteToGame_Steam.Visibility = ESlateVisibility::Collapsed;
		}

		if (ActionFriend.bHasReceivedFriendRequest && !ActionFriend.bIsFirstPartyOnlyFriend)
		{
			FriendAction_AcceptFriendRequest.Visibility = ESlateVisibility::Visible;
			FriendAction_DeclineFriendRequest.Visibility = ESlateVisibility::Visible;
		}
		else
		{
			FriendAction_AcceptFriendRequest.Visibility = ESlateVisibility::Collapsed;
			FriendAction_DeclineFriendRequest.Visibility = ESlateVisibility::Collapsed;
		}

		if (ActionFriend.bHasSentFriendRequest && !ActionFriend.bIsFirstPartyOnlyFriend)
		{
			FriendAction_CancelFriendRequest.Visibility = ESlateVisibility::Visible;
		}
		else
		{
			FriendAction_CancelFriendRequest.Visibility = ESlateVisibility::Collapsed;
		}

		if (ActionFriend.bIsBlocked && !ActionFriend.bIsFirstPartyOnlyFriend)
		{
			FriendAction_Unblock.Visibility = ESlateVisibility::Visible;
		}
		else
		{
			FriendAction_Unblock.Visibility = ESlateVisibility::Collapsed;
		}

		if (ActionFriend.bIsFriend && !ActionFriend.bIsBlocked && !ActionFriend.bIsFirstPartyOnlyFriend)
		{
			FriendAction_Block.Visibility = ESlateVisibility::Visible;
		}
		else
		{
			FriendAction_Block.Visibility = ESlateVisibility::Collapsed;
		}

		if (ActionFriend.bIsFriend && !ActionFriend.bIsFirstPartyOnlyFriend)
		{
			FriendAction_Unfriend.Visibility = ESlateVisibility::Visible;
		}
		else
		{
			FriendAction_Unfriend.Visibility = ESlateVisibility::Collapsed;
		}

		if (!ActionFriend.bIsFriend && !ActionFriend.bHasReceivedFriendRequest && !ActionFriend.bHasSentFriendRequest && !ActionFriend.bIsFirstPartyOnlyFriend)
		{
			FriendAction_RequestFriend.Visibility = ESlateVisibility::Visible;
		}
		else
		{
			FriendAction_RequestFriend.Visibility = ESlateVisibility::Collapsed;
		}
	}
	
	UFUNCTION()
	void OnCloseFriendsList()
	{
		FriendListState = EFriendListState::None;
		UpdateFriendList();
	}

	UFUNCTION()
	void OnAddFriend()
	{
		OpenFriendSearch();
		GetAudioManager().UI_PopupMessageOpen();
	}

	UFUNCTION()
	void OnBlockList()
	{
		OpenBlockList();
		GetAudioManager().UI_PopupMessageOpen();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnFocusReceived(FGeometry MyGeometry, FFocusEvent InFocusEvent)
	{
		if (FriendListState == EFriendListState::FriendAction || FriendListState == EFriendListState::FriendSearchAction || FriendListState == EFriendListState::BlockListAction)
		{
			if (FriendListState == EFriendListState::BlockListAction)
				FriendListState = EFriendListState::BlockList;
			else if (FriendListState == EFriendListState::FriendSearchAction)
				FriendListState = EFriendListState::FriendSearch;
			else
				FriendListState = EFriendListState::FriendList;
			UpdateFriendList();
		}

		if (FriendListState == EFriendListState::InviteChoice)
		{
			if (bWasFriendsChoiceFocused)
				return FEventReply::Handled().SetUserFocus(ManageEAFriendsButton, InFocusEvent.Cause);
			else if (bIsSteam)
				return FEventReply::Handled().SetUserFocus(SendInviteChoiceButton_Steam, InFocusEvent.Cause);
			else
				return FEventReply::Handled().SetUserFocus(SendInviteChoiceButton_Origin, InFocusEvent.Cause);
		}
		else if (FriendListState == EFriendListState::HostChoice)
		{
			return FEventReply::Handled().SetUserFocus(HostChoiceButton_Steam, InFocusEvent.Cause);
		}
		else if (FriendListState == EFriendListState::BlockList)
		{
			auto BlockListWidgets = BlockList.GetDisplayedEntryWidgets();
			auto SelectedBlockListWidget = BlockList.GetSelectedEntryWidget();
			if (SelectedBlockListWidget != nullptr)
			{
				bAwaitingFocus = false;
				return FEventReply::Handled().SetUserFocus(SelectedBlockListWidget, InFocusEvent.Cause);
			}
			else if (BlockListWidgets.Num() != 0 && BlockListWidgets[0] != nullptr)
			{
				bAwaitingFocus = false;
				return FEventReply::Handled().SetUserFocus(BlockListWidgets[0], InFocusEvent.Cause);
			}
			else
			{
				bAwaitingFocus = true;
				AwaitingFocusCause = InFocusEvent.Cause;
				return FEventReply::Handled();
			}
		}
		else if (FriendListState == EFriendListState::FriendList)
		{
			auto Widgets = FriendList.GetDisplayedEntryWidgets();
			auto SelectedWidget = FriendList.GetSelectedEntryWidget();
			if (SelectedWidget != nullptr && !IsFriendListLoading())
			{
				bAwaitingFocus = false;
				return FEventReply::Handled().SetUserFocus(SelectedWidget, InFocusEvent.Cause);
			}
			else if (Widgets.Num() != 0 && Widgets[0] != nullptr && !IsFriendListLoading())
			{
				bAwaitingFocus = false;
				return FEventReply::Handled().SetUserFocus(Widgets[0], InFocusEvent.Cause);
			}
			else
			{
				bAwaitingFocus = true;
				AwaitingFocusCause = InFocusEvent.Cause;
				return FEventReply::Handled();
			}
		}
		else if (FriendListState == EFriendListState::FriendSearch)
		{
			if (ShouldShowSearchInputBox())
			{
				bAwaitingFocus = false;
				return FEventReply::Handled().SetUserFocus(SearchInputBox, InFocusEvent.Cause);
			}

			auto Widgets = SearchList.GetDisplayedEntryWidgets();
			auto SelectedWidget = SearchList.GetSelectedEntryWidget();
			if (SelectedWidget != nullptr)
			{
				bAwaitingFocus = false;
				return FEventReply::Handled().SetUserFocus(SelectedWidget, InFocusEvent.Cause);
			}
			else if (Widgets.Num() != 0 && Widgets[0] != nullptr)
			{
				bAwaitingFocus = false;
				return FEventReply::Handled().SetUserFocus(Widgets[0], InFocusEvent.Cause);
			}
			else
			{
				bAwaitingFocus = true;
				AwaitingFocusCause = InFocusEvent.Cause;
				return FEventReply::Handled();
			}
		}
		else
		{
			return FEventReply::Handled();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnFocusLost(FFocusEvent InFocusEvent)
	{
		bAwaitingFocus = false;
	}

	bool IsFriendListLoading()
	{
		return Online::IsFriendsListLoading();
	}

	void UpdateFocus()
	{
		if (bAwaitingFocus)
		{
			if (FriendListState == EFriendListState::FriendSearch)
			{
				if (ShouldShowSearchInputBox())
				{
					Widget::SetAllPlayerUIFocusWithCause(SearchInputBox, AwaitingFocusCause);
					bAwaitingFocus = false;
				}
				else
				{
					auto Widgets = SearchList.GetDisplayedEntryWidgets();
					if (Widgets.Num() != 0 && Widgets[0] != nullptr)
					{
						Widget::SetAllPlayerUIFocusWithCause(Widgets[0], AwaitingFocusCause);
						bAwaitingFocus = false;
					}
				}
			}
			else if (FriendListState == EFriendListState::BlockList)
			{
				auto Widgets = BlockList.GetDisplayedEntryWidgets();
				if (Widgets.Num() != 0 && Widgets[0] != nullptr)
				{
					Widget::SetAllPlayerUIFocusWithCause(Widgets[0], AwaitingFocusCause);
					bAwaitingFocus = false;
				}
			}
			else if (FriendListState == EFriendListState::FriendList)
			{
				auto Widgets = FriendList.GetDisplayedEntryWidgets();
				if (Widgets.Num() != 0 && Widgets[0] != nullptr && !IsFriendListLoading())
				{
					Widget::SetAllPlayerUIFocusWithCause(Widgets[0], AwaitingFocusCause);
					bAwaitingFocus = false;
				}
			}
			else
			{
				bAwaitingFocus = false;
			}
		}
	}

	bool ShouldShowSearchInputBox()
	{
		return !Online::RequiresTextInputPrompt();
	}

	void RefreshFriends()
	{
		TArray<UHazeOnlineFriend> FriendData;
		Online::GetFriends(FriendData);

		FriendList.Visibility = !IsFriendListLoading() ? ESlateVisibility::Visible : ESlateVisibility::Hidden;
		FriendListLoadingSpinner.Visibility = IsFriendListLoading() ? ESlateVisibility::Visible : ESlateVisibility::Hidden;

		if (FriendData == Friends)
			return;

		Friends = FriendData;

		FriendObjects.Reset();
		for (auto Friend : Friends)
			FriendObjects.Add(Friend);

		FriendList.SetListItems(FriendObjects);
		FriendList.RequestRefresh();

		auto SelectedItem = FriendList.GetSelectedItem();
		if (SelectedItem != nullptr)
			FriendList.ScrollItemIntoView(SelectedItem);
	}

	void RefreshSearch()
	{
		TArray<UHazeOnlineFriend> SearchData;
		Online::GetSearchedFriends(SearchData);

		if (ShouldShowSearchInputBox())
			SearchInputBox.Visibility = ESlateVisibility::Visible;
		else
			SearchInputBox.Visibility = ESlateVisibility::Collapsed;

		if (SearchData == SearchFriends)
			return;

		SearchFriends.Reset();
		SearchObjects.Reset();
		for (auto Friend : SearchData)
		{
			SearchFriends.Add(Friend);
			SearchObjects.Add(Friend);
		}

		SearchList.SetListItems(SearchObjects);
		SearchList.RequestRefresh();
	}

	void RefreshBlockList()
	{
		TArray<UHazeOnlineFriend> BlockListData;
		Online::GetBlockList(BlockListData);

		if (BlockListData == BlockListFriends)
			return;

		BlockListFriends.Reset();
		BlockListObjects.Reset();
		for (auto Friend : BlockListData)
		{
			BlockListFriends.Add(Friend);
			BlockListObjects.Add(Friend);
		}

		BlockList.SetListItems(BlockListObjects);
		BlockList.RequestRefresh();
	}

	UFUNCTION()
	private void OnChapterPickerChanged()
	{
		if (Lobby.LobbyOwner.IsLocal())
		{
			Lobby::Menu_LobbySelectStart(
				EHazeLobbyStartType::ChapterSelect,
				ChapterPicker.SelectedChapter.ProgressPoint,
				ChapterPicker.SelectedChapter.ProgressPoint
			);
		}
	}

	UFUNCTION()
	private void OnMinigamePicked(FHazeProgressPointRef ProgressPoint)
	{
		if (Lobby.LobbyOwner.IsLocal())
		{
			Lobby::Menu_LobbySelectStart(
				EHazeLobbyStartType::PickMinigame,
				MinigamePicker.SelectedMinigame,
				MinigamePicker.SelectedMinigame
			);
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_StartTypeChanged(EHazeLobbyStartType PrevStartType, EHazeLobbyStartType NewStartType) {}

	UFUNCTION(BlueprintPure)
	bool ShouldShowFriendsPassInfo()
	{
		if (Online::GetGameEntitlement() == EHazeEntitlement::FriendPass)
			return false;
		if (Lobby == nullptr)
			return false;
		if (Lobby.Network != EHazeLobbyNetwork::Host)
			return false;
		if (!Lobby.LobbyOwner.IsLocal())
			return false;
		if (Lobby.NumIdentitiesInLobby() >= 2)
			return false;
		return true;
	}

	UFUNCTION(BlueprintPure)
	bool IsTrialMode()
	{
		if (Online::GetGameEntitlement() == EHazeEntitlement::FullGame)
			return false;

		auto HazeGameInstance = Game::GetHazeGameInstance();
		if (HazeGameInstance == nullptr)
			return false;
		if (HazeGameInstance.bRemoteEntitlementSynced && HazeGameInstance.RemoteEntitlement == EHazeEntitlement::FullGame)
			return false;

		return true;
	}

	UFUNCTION(BlueprintPure)
	bool ShouldShowFullGameIndicator()
	{
		// If this is a trial lobby, show that
		if (IsTrialMode())
			return false;

		// If we are friend's pass in a full game lobby, show it
		if (Online::GetGameEntitlement() == EHazeEntitlement::FriendPass)
			return true;

		// Don't need to show full game to someone who owns the game
		return false;
	}

	UFUNCTION()
	void ShowFriendsPassPopup()
	{
		bInFriendsPassPopup = true;
		BP_ShowFriendsPassPopup();
	}

	UFUNCTION()
	void HideFriendsPassPopup()
	{
		bInFriendsPassPopup = false;
		BP_HideFriendsPassPopup();
	}

	UFUNCTION()
	void ShowFriendsPassMoreInfo()
	{
		Online::ShowFriendsPassInfo();
		HideFriendsPassPopup();
	}

	UFUNCTION(BlueprintEvent)
	void BP_ShowFriendsPassPopup() {}

	UFUNCTION(BlueprintEvent)
	void BP_HideFriendsPassPopup() {}

	UFUNCTION(BlueprintEvent)
	FChapterSelectButtons GetButtonsForNarration()
	{
		return FChapterSelectButtons();
	}

	void InternalNarrateFullMenu()
	{
		if (!Game::IsNarrationEnabled())
			return;

		FChapterSelectButtons Buttons = GetButtonsForNarration();

		FString FullNarration = "";
		FString ButtonNarration;
		
		switch (CurrentStartType)
		{
			case EHazeLobbyStartType::NewGame:
				FullNarration += Buttons.NewGame.Text.ToString() + ", ";
				break;
			case EHazeLobbyStartType::Continue:
				FullNarration += Buttons.Continue.Text.ToString() + ", ";
				if (bHasContinue)
				{
					FullNarration += ConinueNarrationText;
				}
				break;
			case EHazeLobbyStartType::ChapterSelect:
				FullNarration += Buttons.ChapterSelect.Text.ToString() + ", ";
				FullNarration += ChapterPicker.GetNarrationString(true);
				break;
			case EHazeLobbyStartType::PickMinigame:
				FullNarration += Buttons.Minigames.Text.ToString() + ", ";
				{
					auto MinigameRow = MinigamePicker.GetSelectedRow();
					if (MinigameRow != nullptr)
					{
						FullNarration += MinigameRow.MinigameChapter.Name.ToString() + ", ";
					}
				}
				break;
		}

		FString ControlNarration;

		// If we have a joinable slot narrate the join button
		if (Lobby != nullptr && Lobby.NumIdentitiesInLobby() < 2)
		{
			if (GetLobbyOwnerWidget().MakeNarrationString(ButtonNarration))
				ControlNarration += ButtonNarration + ", ";
		}

		if (Buttons.LeftTab.MakeNarrationString(ButtonNarration))
			ControlNarration += ButtonNarration + ", ";

		if (Buttons.RightTab.MakeNarrationString(ButtonNarration))
			ControlNarration += ButtonNarration + ", ";

		if (Buttons.Back.MakeNarrationString(ButtonNarration))
			ControlNarration += ButtonNarration + ", ";

		if (CanInvitePlayer() && Buttons.Invite.MakeNarrationString(ButtonNarration))
			ControlNarration += ButtonNarration + ", ";

		if (ShouldShowFriendsPassInfo() && Buttons.FP.MakeNarrationString(ButtonNarration))
			ControlNarration += ButtonNarration + ", ";

		if (CanProceedToCharacterSelect() && Buttons.Proceed.MakeNarrationString(ButtonNarration))
			ControlNarration += ButtonNarration + ", ";

		if (!ControlNarration.IsEmpty())
			FullNarration += "Menu Controls, " + ControlNarration;

		Game::NarrateString(FullNarration);
	}

	UFUNCTION()
	void NarrateFullMenu()
	{
		bNarrateNextTick = true;
	}
};

struct FKCodeHandler
{
	int Progress = -1;

	bool AddInput(UChapterSelectWidget Widget, FKey Key)
	{
		bool bCanProceed = false;
		bool bShouldEat = false;

		switch (Progress+1)
		{
			case 0:
			case 1:
				bCanProceed = (Key == EKeys::Up) || (Key == EKeys::Gamepad_DPad_Up);
			break;
			case 2:
			case 3:
				bCanProceed = (Key == EKeys::Down) || (Key == EKeys::Gamepad_DPad_Down);
			break;
			case 4:
			case 6:
				bCanProceed = (Key == EKeys::Left) || (Key == EKeys::Gamepad_DPad_Left);
			break;
			case 5:
			case 7:
				bCanProceed = (Key == EKeys::Right) || (Key == EKeys::Gamepad_DPad_Right);
			break;
			case 8:
				bCanProceed = (Key == EKeys::B) || (Key == EKeys::Gamepad_FaceButton_Right);
				bShouldEat = true;
			break;
			case 9:
				bCanProceed = (Key == EKeys::A) || (Key == EKeys::Gamepad_FaceButton_Bottom);
				bShouldEat = true;
			break;
		}

		if (bCanProceed)
			Progress += 1;
		else if (Progress != -1)
			Progress = -1;

		if (Progress >= 9)
		{
			PrintToScreen("Good Morning World!", Duration = 5.f, Color = FLinearColor::Green);
			System::ExecuteConsoleCommand("Haze.UnlockAllChapters");
			System::ExecuteConsoleCommand("Haze.UnlockAllMinigames");

			if (!Widget.bHasContinue)
			{
				Save::SaveAtProgressPoint(Progress::GetProgressPointRefID(Widget.ChapterDatabase.InitialChapter), bQuietSave = true);
				Widget.bHasContinue = true;
				Widget.ChapterPicker.SelectChapter(Widget.ChapterDatabase.GetInitialChapter());
				Widget.ContinueChapter = Widget.ChapterDatabase.InitialChapter;
				Widget.ContinuePoint = Widget.ChapterDatabase.InitialChapter;
			}

			FHazeChapter Chapter = Widget.ChapterDatabase.GetChapterByProgressPoint(Widget.ContinueChapter);
			FHazeChapterGroup Group = Widget.ChapterDatabase.GetChapterGroup(Chapter);
			Widget.BP_SetContinueChapter(Group, Chapter);
			Widget.MinigamePicker.Initialize();
		}

		return bShouldEat;
	}
};


struct FFriendSorter
{
	UHazeOnlineFriend Friend;
	int DisplayOrder = 0;

	int opCmp(const FFriendSorter& Other) const
	{
		if (DisplayOrder < Other.DisplayOrder)
			return -1;
		else if (DisplayOrder > Other.DisplayOrder)
			return 1;
		else
			return 0;
	}
}

class ULobbyFriendWidget : UHazeUserWidget
{
	UHazeOnlineFriend Friend;

	UPROPERTY(Meta = (BindWidget))
	UTextBlock NameWidget;
	UPROPERTY(Meta = (BindWidget))
	UTextBlock StateWidget;
	UPROPERTY(Meta = (BindWidget))
	UBorder BackgroundBorder;

	UPROPERTY(Meta = (BindWidget))
	UWidget FriendIcon_Steam;
	UPROPERTY(Meta = (BindWidget))
	UWidget FriendIcon_Origin;

	UPROPERTY(Meta = (BindWidget))
	UWidget FirstPartyIdBox;
	UPROPERTY(Meta = (BindWidget))
	UTextBlock FirstPartyNetworkName;
	UPROPERTY(Meta = (BindWidget))
	UWidget FirstPartyIcon_Steam;
	UPROPERTY(Meta = (BindWidget))
	UTextBlock FirstPartyIdWidget;

	UPROPERTY(BlueprintReadOnly)
	bool bFocused = false;

	UPROPERTY(BlueprintReadOnly)
	bool bFocusedByMouse = false;

	UPROPERTY(BlueprintReadOnly)
	bool bHovered = false;

	UPROPERTY(BlueprintReadOnly)
	bool bPressed = false;

	private UHazeOnlineFriend PendingActionFriend;
	int InternalMouseOverCount = 0;

	UFUNCTION()
	void SetEntryData(UObject InFriend)
	{
		Friend = Cast<UHazeOnlineFriend>(InFriend);
		Update();
	}

	UFUNCTION()
	private void OnShowActions()
	{
		auto LobbyWidget = Cast<UChapterSelectWidget>(GetParentWidgetOfClass(UChapterSelectWidget::StaticClass()));
		LobbyWidget.OpenFriendAction(Friend);
		GetAudioManager().UI_OnSelectionConfirmed();
	}

	bool ShouldShowButtons() const
	{
		if (bFocused)
			return true;
		EHazePlayerControllerType Type = Lobby::GetMostLikelyControllerType();
		if (Type == EHazePlayerControllerType::Keyboard)
			return true;
		return false;
	}

	FSlateColor MakeFromHex(uint32 HexCode)
	{
		FSlateColor Color;
		Color.SpecifiedColor = FColor(HexCode).ReinterpretAsLinear();
		Color.ColorUseRule = ESlateColorStylingMode::UseColor_Specified;
		return Color;
	}

	void Update()
	{
		NameWidget.SetText(Friend.Nickname);
		NameWidget.SetColorAndOpacity(MakeFromHex(0xffffffff));

		if (bPressed)
		{
			BackgroundBorder.SetBrushColor(MakeFromHex(0xfffbbea1).SpecifiedColor);

			NameWidget.SetColorAndOpacity(MakeFromHex(0xff190200));
			FirstPartyNetworkName.SetColorAndOpacity(MakeFromHex(0xff190200));
			FirstPartyIdWidget.SetColorAndOpacity(MakeFromHex(0xff190200));
			StateWidget.SetColorAndOpacity(MakeFromHex(0xff190200));
		}
		else if (IsHoveredOrActive())
		{
			BackgroundBorder.SetBrushColor(MakeFromHex(0xfffd3a09).SpecifiedColor);

			NameWidget.SetColorAndOpacity(MakeFromHex(0xff190200));
			FirstPartyNetworkName.SetColorAndOpacity(MakeFromHex(0xff190200));
			FirstPartyIdWidget.SetColorAndOpacity(MakeFromHex(0xff190200));
			StateWidget.SetColorAndOpacity(MakeFromHex(0xff190200));
		}
		else
		{
			BackgroundBorder.SetBrushColor(MakeFromHex(0x20000000).SpecifiedColor);

			NameWidget.SetColorAndOpacity(MakeFromHex(0xffffffff));
			FirstPartyNetworkName.SetColorAndOpacity(MakeFromHex(0xffffffff));
			FirstPartyIdWidget.SetColorAndOpacity(MakeFromHex(0xffffffff));
			StateWidget.SetColorAndOpacity(MakeFromHex(0xff6f6f6f));
		}

		if (Friend.bIsBlocked)
		{
			StateWidget.SetText(NSLOCTEXT("LobbyFriend", "BlockedState", "Blocked"));
		}
		else if (Friend.bHasSentFriendRequest)
		{
			// StateWidget.SetText(NSLOCTEXT("LobbyFriend", "FriendRequestSent", "Sent Friend Request"));
			StateWidget.SetText(FText());
			// StateWidget.SetColorAndOpacity(MakeFromHex(0xffffffff));
		}
		else if (Friend.bHasReceivedFriendRequest)
		{
			StateWidget.SetText(NSLOCTEXT("LobbyFriend", "FriendRequestReceived", "Received Friend Request"));
			// StateWidget.SetColorAndOpacity(MakeFromHex(0xffffffff));
		}
		else if (!Friend.bIsFriend)
		{
			StateWidget.SetText(NSLOCTEXT("LobbyFriend", "NotFriendState", "Not Friends"));
			// StateWidget.SetColorAndOpacity(MakeFromHex(0xff858585));
		}
		else if (Friend.bIsInJoinableLobby)
		{
			StateWidget.SetText(NSLOCTEXT("LobbyFriend", "ThisGameStateLobby", "It Takes Two - Online Lobby"));
			if (!bPressed && !IsHoveredOrActive())
				StateWidget.SetColorAndOpacity(MakeFromHex(0xffffaa0d));
		}
		else if (Friend.bPlayingOtherGame)
		{
			StateWidget.SetText(NSLOCTEXT("LobbyFriend", "OtherGameState", "Playing Other Game"));
		}
		else if (Friend.bPlayingThisGame)
		{
			StateWidget.SetText(NSLOCTEXT("LobbyFriend", "ThisGameState", "Playing It Takes Two"));
			if (!bPressed && !IsHoveredOrActive())
				StateWidget.SetColorAndOpacity(MakeFromHex(0xffffaa0d));
		}
		else if (Friend.bOnline)
		{
			StateWidget.SetText(NSLOCTEXT("LobbyFriend", "OnlineState", "Online"));
			if (!bPressed && !IsHoveredOrActive())
				StateWidget.SetColorAndOpacity(MakeFromHex(0xffffaa0d));
		}
		else
		{
			if (Friend.FirstPartyType == EHazeOnlineFirstPartyType::None)
			{
				// An EA-only friend doesn't show the Offline text, because EA presence doesn't work that way
				StateWidget.SetText(FText());
			}
			else
			{
				StateWidget.SetText(NSLOCTEXT("LobbyFriend", "OfflineState", "Offline"));
			}

			// StateWidget.SetColorAndOpacity(MakeFromHex(0xff888888));
			// NameWidget.SetColorAndOpacity(MakeFromHex(0xff888888));

			// if (!bPressed && !IsHoveredOrActive())
			// 	BackgroundBorder.SetBrushColor(MakeFromHex(0xff050505).SpecifiedColor);
		}

		if (Friend.bIsFirstPartyOnlyFriend)
		{
			FirstPartyIdBox.Visibility = ESlateVisibility::Collapsed;

			switch (Friend.FirstPartyType)
			{
				case EHazeOnlineFirstPartyType::Steam:
				{
					FriendIcon_Origin.Visibility = ESlateVisibility::Collapsed;
					FriendIcon_Steam.Visibility = ESlateVisibility::Visible;
				}
				break;
			}
		}
		else
		{
			FriendIcon_Origin.Visibility = ESlateVisibility::Visible;
			FriendIcon_Steam.Visibility = ESlateVisibility::Collapsed;

			switch (Friend.FirstPartyType)
			{
				case EHazeOnlineFirstPartyType::Steam:
				{
					FirstPartyNetworkName.SetText(NSLOCTEXT("LobbyFriend", "SteamNetworkLabel", "Steam:"));

					FString ClippedName = Friend.FirstPartyNickname.ToString();
					if (ClippedName.Len() > 20)
						ClippedName = ClippedName.Mid(0, 20) + "...";

					FirstPartyIdWidget.SetText(FText::FromString(ClippedName));
					FirstPartyIdBox.Visibility = ESlateVisibility::Visible;
					FirstPartyIcon_Steam.Visibility = ESlateVisibility::Visible;
				}
				break;
				case EHazeOnlineFirstPartyType::None:
					FirstPartyIdBox.Visibility = ESlateVisibility::Collapsed;
					FirstPartyIcon_Steam.Visibility = ESlateVisibility::Collapsed;
				break;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		// Update on tick for now, might want to do something else later
		Update();
	}

	UFUNCTION(BlueprintPure)
	bool IsHoveredOrActive()
	{
		if (bFocused || bHovered)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnFocusReceived(FGeometry MyGeometry, FFocusEvent InFocusEvent)
	{
		bFocused = true;
		bFocusedByMouse = (InFocusEvent.Cause == EFocusCause::Mouse);

		if(!bFocusedByMouse)
		{
			GetAudioManager().UI_OnSelectionChanged();
		}
		else
		{
			const float NormalizedInstanceCount = FMath::Clamp(GetAudioManager().MenuWidgetMouseHoverSoundCount / 5.f, 0.f, 1.f);
			UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_Menu_ButtonHover_TriggerRate", NormalizedInstanceCount);
			GetAudioManager().UI_OnSelectionChanged_Mouse();

			if(InternalMouseOverCount == 0)
			{
				GetAudioManager().MenuWidgetMouseHoverSoundCount ++;
				InternalMouseOverCount ++;
				System::SetTimer(this, n"ResetMouseOverRTPC", 0.25f, false);
			}
		}

		auto LobbyWidget = Cast<UChapterSelectWidget>(GetParentWidgetOfClass(UChapterSelectWidget::StaticClass()));
		if (LobbyWidget.FriendListState == EFriendListState::FriendSearch)
		{
			LobbyWidget.SearchList.SetSelectedItem(Friend);
			if (!bFocusedByMouse)
				LobbyWidget.SearchList.ScrollItemIntoView(this);
		}
		else if (LobbyWidget.FriendListState == EFriendListState::BlockList)
		{
			LobbyWidget.BlockList.SetSelectedItem(Friend);
			if (!bFocusedByMouse)
				LobbyWidget.BlockList.ScrollItemIntoView(this);
		}
		else
		{
			LobbyWidget.FriendList.SetSelectedItem(Friend);
			if (!bFocusedByMouse)
				LobbyWidget.FriendList.ScrollItemIntoView(this);
		}

		return FEventReply::Handled();
	}

	UFUNCTION()
	void ResetMouseOverRTPC()
	{
		GetAudioManager().MenuWidgetMouseHoverSoundCount --;
		InternalMouseOverCount --;
	}

	UFUNCTION(BlueprintOverride)
	void OnFocusLost(FFocusEvent InFocusEvent)
	{
		bFocused = false;
		bPressed = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnMouseEnter(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnMouseLeave(FPointerEvent MouseEvent)
	{
		bHovered = false;
		bPressed = false;
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonDown(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (MouseEvent.GetEffectingButton() == EKeys::LeftMouseButton)
		{
			bPressed = true;
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonUp(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (MouseEvent.GetEffectingButton() == EKeys::LeftMouseButton)
		{
			if (bPressed)
				OnShowActions();
			bPressed = false;
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseMove(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (MouseEvent.CursorDelta.IsNearlyZero())
			return FEventReply::Unhandled();

		bHovered = true;

		auto LobbyWidget = Cast<UChapterSelectWidget>(GetParentWidgetOfClass(UChapterSelectWidget::StaticClass()));
		if (LobbyWidget.SearchInputBox.HasAnyUserFocus())
			return FEventReply::Unhandled();
		else
			return FEventReply::Unhandled().SetUserFocus(this, EFocusCause::Mouse);
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry MyGeometry, FKeyEvent InKeyEvent)
	{
		if (InKeyEvent.GetKey() == EKeys::Gamepad_FaceButton_Bottom || InKeyEvent.GetKey() == EKeys::Enter)
		{
			bPressed = true;
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyUp(FGeometry MyGeometry, FKeyEvent InKeyEvent)
	{
		if (InKeyEvent.GetKey() == EKeys::Gamepad_FaceButton_Bottom || InKeyEvent.GetKey() == EKeys::Enter)
		{
			if (bPressed)
				OnShowActions();
			bPressed = false;
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}
}