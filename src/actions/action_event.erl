% Nitrogen Web Framework for Erlang
% Copyright (c) 2008-2009 Rusty Klophaus
% See MIT-LICENSE for licensing information.

-module (action_event).
-include ("wf.inc").
-compile(export_all).

render_action(#event { postback=Postback, actions=Actions, trigger=Trigger, target=Target, type=Type, delay=Delay, delegate=Delegate, extra_param=ExtraParam}) -> 
	PostbackScript = wf_event:generate_postback_script(Postback, Trigger, Target, Delegate, ExtraParam),
	SystemPostbackScript = wf_event:generate_system_postback_script(Postback, Trigger, Target, Delegate),
	WireAction = #wire { trigger=Trigger, target=Target, actions=Actions },

	Script = case Type of
		
		%%% SYSTEM EVENTS %%%
		% Trigger a system postback immediately...
		system when Delay == 0 ->
			[
				SystemPostbackScript, WireAction
			];
		
		% Trigger a system postback after some delay...
		system ->
			TempID = wf:temp_id(),
			[
				wf:f("document.~s = function() {", [TempID]), SystemPostbackScript, WireAction, "};",
				wf:f("setTimeout(\"document.~s(); document.~s=null;\", ~p);", [TempID, TempID, Delay])
			];
			
		%%% USER EVENTS %%%
		% Run the event when an enter key is hit, such as in an input textbox
		enterkey ->
			[
				wf:f("Nitrogen.$observe_event(obj('~s'), 'keypress', function anonymous(event) {", [wf:to_js_id(Trigger)]),
				"if (Nitrogen.$is_enter_key(event)) {", PostbackScript, WireAction, "return false; }",
				"});"
			];
		
		% Run the event after a specified amount of time
		timer ->
			TempID = wf:temp_id(),
			[
				wf:f("document.~s = function() {", [TempID]), PostbackScript, WireAction, "};",
				wf:f("setTimeout(\"document.~s(); document.~s=null;\", ~p);", [TempID, TempID, Delay])
			];
			
		default ->
			[
				PostbackScript, WireAction
			];
		
		% Run some other Javascript event (click, mouseover, mouseout, etc.)
		_ ->
			[
				wf:f("Nitrogen.$observe_event(obj('~s'), '~s', function anonymous(event) {", [wf:to_js_id(Trigger), Type]), 
				PostbackScript, WireAction, 
				"});"
			]
			
	end,
	Script.