function CheeseActionButton_Update(self)
	if ( HasAction(self.action) ) then
		if ( not self.cheeseEventsRegistered ) then
			Cheese_RegisterEvent("CHEESE_SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", self, CheeseActionButton_OnEventOverlayGlowShow);
			Cheese_RegisterEvent("CHEESE_SPELL_ACTIVATION_OVERLAY_GLOW_HIDE", self, CheeseActionButton_OnEventOverlayGlowHide);
			self.cheeseEventsRegistered = true;
		end
	else
		if ( self.cheeseEventsRegistered ) then
			Cheese_UnregisterEvent("CHEESE_SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", self);
			Cheese_UnregisterEvent("CHEESE_SPELL_ACTIVATION_OVERLAY_GLOW_HIDE", self);
			self.cheeseEventsRegistered = nil;
		end
	end

	CheeseActionButton_UpdateOverlayGlow(self);
end

hooksecurefunc("ActionButton_Update", CheeseActionButton_Update);

--Overlay stuff
local unusedOverlayGlows = {};
local numOverlays = 0;

local function IsAnimPlaying(self)
	return self.isPlaying;
end

function CheeseActionButton_GetOverlayGlow()
	local overlay = tremove(unusedOverlayGlows);
	if ( not overlay ) then
		numOverlays = numOverlays + 1;
		overlay = CreateFrame("Frame", "CheeseActionButtonOverlay"..numOverlays, UIParent, "CheeseActionBarButtonSpellActivationAlert");
		local animOut = overlay.animOut;
		animOut.isPlaying = false;
		animOut.IsPlaying = IsAnimPlaying;
	end
	return overlay;
end

-- Returns the globalID of the spell on this action button, whether it's a
-- direct spell slot or a macro. Returns nil if the button has no spell.
local function GetActionButtonSpellID(self)
	local actionType, id, subType, globalID = GetActionInfo(self.action);
	if ( actionType == "spell" ) then
		return globalID;
	elseif ( actionType == "macro" ) then
		local spellName, rank = GetMacroSpell(id);
		if ( not spellName ) then return nil; end
		local link = GetSpellLink(spellName, rank);
		if ( not link ) then return nil; end
		return tonumber(link:match("Hspell:(%d+)"));
	end
	return nil;
end

function CheeseActionButton_UpdateOverlayGlow(self)
	local spellID = GetActionButtonSpellID(self);
	if ( spellID and Cheese_IsSpellOverlayed(spellID) ) then
		CheeseActionButton_ShowOverlayGlow(self);
	else
		CheeseActionButton_HideOverlayGlow(self);
	end
end

function CheeseActionButton_ShowOverlayGlow(self)
	if ( self.cheeseOverlay ) then
		if ( self.cheeseOverlay.animOut:IsPlaying() ) then
			self.cheeseOverlay.animOut:Stop();
			self.cheeseOverlay.animIn:Play();
		end
	else
		self.cheeseOverlay = CheeseActionButton_GetOverlayGlow();
		local frameWidth, frameHeight = self:GetSize();
		self.cheeseOverlay:SetParent(self);
		self.cheeseOverlay:ClearAllPoints();
		--Make the height/width available before the next frame:
		self.cheeseOverlay:SetSize(frameWidth * 1.4, frameHeight * 1.4);
		self.cheeseOverlay:SetPoint("TOPLEFT", self, "TOPLEFT", -frameWidth * 0.2, frameHeight * 0.2);
		self.cheeseOverlay:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", frameWidth * 0.2, -frameHeight * 0.2);
		self.cheeseOverlay.animIn:Play();
	end
end

function CheeseActionButton_HideOverlayGlow(self)
	if ( self.cheeseOverlay ) then
		if ( self.cheeseOverlay.animIn:IsPlaying() ) then
			self.cheeseOverlay.animIn:Stop();
		end
		if ( self:IsVisible() ) then
			self.cheeseOverlay.animOut:Play();
		else
			CheeseActionButton_OverlayGlowAnimOutFinished(self.cheeseOverlay.animOut);	--We aren't shown anyway, so we'll instantly hide it.
		end
	end
end

function CheeseActionButton_OverlayGlowAnimOutFinished(animGroup)
	local overlay = animGroup:GetParent();
	local actionButton = overlay:GetParent();
	overlay:Hide();
	tinsert(unusedOverlayGlows, overlay);
	actionButton.cheeseOverlay = nil;
end

function CheeseActionButton_OnEvent(self, event)
	if ( event == "ACTIONBAR_PAGE_CHANGED" or event == "UPDATE_BONUS_ACTIONBAR" ) then
		local actionType, id, subType, globalID = GetActionInfo(self.action);
		if ( actionType == "spell" and globalID == 0 ) then
			CheeseActionButton_HideOverlayGlow(self);
		end
		return;
	end
end

hooksecurefunc("ActionButton_OnEvent", CheeseActionButton_OnEvent);

function CheeseActionButton_OnEventOverlayGlowShow(self, arg1)
	-- arg1 = globalID of the spell whose glow just became active.
	-- Fire if this button's spell (direct or via macro) matches.
	local spellID = GetActionButtonSpellID(self);
	if ( spellID and spellID == arg1 ) then
		CheeseActionButton_ShowOverlayGlow(self);
	end
end

function CheeseActionButton_OnEventOverlayGlowHide(self, arg1)
	local spellID = GetActionButtonSpellID(self);
	if ( spellID and spellID == arg1 ) then
		CheeseActionButton_HideOverlayGlow(self);
	end
end
