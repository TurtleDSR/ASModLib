import Rice.MessageDialog.MessageDialogData;
import Rice.MessageDialog.MessageDialogStatics;
import Rice.PauseMenu.PauseMenuSingleton;

class UGlobalMenuOverlayWidget : UHazeUserWidget
{
    UPROPERTY(Meta = (BindWidget))
    UVerticalBox GameInviteList;

    UPROPERTY()
    TSubclassOf<UHazeUserWidget> DebugInfoWidget;

    UPROPERTY()
    TSubclassOf<UGameInviteWidget> InviteWidgetClass;
    UPROPERTY()
    TArray<UGameInviteWidget> InviteWidgets;

    UFUNCTION(BlueprintOverride)
    void OnAdded()
    {
        SetWidgetZOrderInLayer(9001);

#if DEBUG
        if(DebugInfoWidget.IsValid())
        {
            auto InfoWidget = Widget::AddFullscreenWidget(DebugInfoWidget, EHazeWidgetLayer::Dev);    
            InfoWidget.SetWidgetPersistent(true);
        }
#endif
    }
    
    UFUNCTION(BlueprintOverride)
    void Tick(FGeometry Geom, float Timer)
    {
        /** Update widgets for game invites */
        UpdateInviteWidgets(Timer);
    }

    bool bHaveTriggeredInvite = false;
    FString TriggeredInviteId;

    void UpdateInviteWidgets(float DeltaTime)
    {
        /** Update widgets for game invites */
        TArray<FHazeOnlineGameInvite> ActiveInvites;
        Online::GetReceivedGameInvites(ActiveInvites);

        // Remove widgets for invites that have expired
        for (int i = ActiveInvites.Num(), Count = InviteWidgets.Num(); i < Count; ++i)
            InviteWidgets[i].RemoveFromParent();
        InviteWidgets.SetNum(ActiveInvites.Num());

        // Update invites that have been received
        for (int i= 0, Count = ActiveInvites.Num(); i < Count; ++i)
        {
            if (InviteWidgets[i] == nullptr)
            {
                InviteWidgets[i] = Cast<UGameInviteWidget>(
                    Widget::CreateWidget(this, InviteWidgetClass.Get())
                );
                GameInviteList.AddChild(InviteWidgets[i]);
            }

            InviteWidgets[i].Invite = ActiveInvites[i];
            InviteWidgets[i].Update();

            if (bHaveTriggeredInvite)
                InviteWidgets[i].Visibility = ESlateVisibility::Hidden;
            else
                InviteWidgets[i].Visibility = ESlateVisibility::SelfHitTestInvisible;

            // If the invite was triggered, show a popup message to answer it
            if (ActiveInvites[i].bIsTriggered && !bHaveTriggeredInvite)
            {
                TriggeredInviteId = ActiveInvites[i].InviteId;
                bHaveTriggeredInvite = true;

                FMessageDialog Dialog;
                Dialog.Message = InviteWidgets[i].InviteText.GetText();
                Dialog.Type = EMessageDialogType::YesNo;
                Dialog.OnClosed.BindUFunction(this, n"OnTriggeredInviteAnswer");
                Dialog.ConfirmText = InviteWidgets[i].AcceptButton.Text;
                Dialog.CancelText = InviteWidgets[i].DeclineButton.Text;
                ShowPopupMessage(Dialog);
                GetAudioManager().UI_PopupMessageOpen();            
            }
        }
    }

    UFUNCTION()
    private void OnTriggeredInviteAnswer(EMessageDialogResponse Response)
    {
        Online::RespondToGameInvite(TriggeredInviteId, Response == EMessageDialogResponse::Yes);
        bHaveTriggeredInvite = false;
    }

}

class UGameInviteWidget : UHazeUserWidget
{
    FHazeOnlineGameInvite Invite;
    UPROPERTY(Meta = (BindWidget))
    UTextBlock InviteText;
    UPROPERTY(Meta = (BindWidget))
    UWidget KeyPromptRow;
    UPROPERTY(Meta = (BindWidget))
    UWidget MouseButtonRow;
    UPROPERTY(Meta = (BindWidget))
    UMenuPromptOrButton DeclineButton;
    UPROPERTY(Meta = (BindWidget))
    UMenuPromptOrButton AcceptButton;
    UPROPERTY(Meta = (BindWidget))
    UProgressBar ProgressTimer;

    UFUNCTION(BlueprintOverride)
    void Construct()
    {
        AcceptButton.bTriggerOnMouseDown = true;
        DeclineButton.bTriggerOnMouseDown = true;

        DeclineButton.OnPressed.AddUFunction(this, n"OnDeclinePressed");
        AcceptButton.OnPressed.AddUFunction(this, n"OnAcceptPressed");
    }

    UFUNCTION()
    void OnDeclinePressed()
    {
        Online::RespondToGameInvite(Invite.InviteId, false);
    }

    UFUNCTION()
    void OnAcceptPressed()
    {
        Online::RespondToGameInvite(Invite.InviteId, true);
    }

    void Update()
    {
        FText Text = NSLOCTEXT("GameInvite", "InviteText", "{0} has invited you to play It Takes Two");
        Text = FText::FromString(Text.ToString().Replace("{0}", Invite.FriendName.ToString()));
        InviteText.Text = Text;

        auto Lobby = Lobby::GetLobby();
        EHazePlayerControllerType ControllerType = Lobby::GetMostLikelyControllerType();

        bool bInPauseMenu = UPauseMenuSingleton::Get().bPauseMenuVisible;
        if ((Lobby == nullptr || !Lobby.HasGameStarted() || bInPauseMenu) && ControllerType == EHazePlayerControllerType::Keyboard)
        {
            MouseButtonRow.Visibility = ESlateVisibility::SelfHitTestInvisible;
            KeyPromptRow.Visibility = ESlateVisibility::Collapsed;
        }
        else
        {
            KeyPromptRow.Visibility = ESlateVisibility::SelfHitTestInvisible;
            MouseButtonRow.Visibility = ESlateVisibility::Collapsed;
        }

        ProgressTimer.SetPercent(Invite.TimeRemaining);
    }
};