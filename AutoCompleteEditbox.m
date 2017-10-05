classdef AutoCompleteEditbox < matlab.mixin.SetGet
    %AUTOCOMPLETEEDITBOX Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        BackgroundColor = [255 255 255]
        CaseSensitive = false
        CompletionList = {'sample string'; 'test string'; 'sample test'}
        Enabled     = true
        FontSize    = 12
        FontWeight  = 'normal'
        FontColor   = [0 0 0]
        HorizontalAlignment = 'left'
    end
    properties (SetAccess = protected)
        Matches % i want the prop list alphabetical but i cba overloading disp() right now
    end
    properties
        Parent      = []
        Position    = [200 200 200 26]
        String      = ''
        TooltipString = ''
        Units       = 'pixels'
        UserData    = []
        Visible     = true
    end
    
    properties (SetAccess = protected) % DEBUG: will change to fully protected
        jTextField
        hTextField
        jComboBox
        hComboBox
    end
    
    events (NotifyAccess = protected)
        EnterKeyPress
    end
    
    %% Constructor
    methods
        function this = AutoCompleteEditbox(parent, varargin)
            if nargin < 1
                parent = gcf;
            end
            
            % create the uicontrols
            createObjectInFigure(this, parent);
            
            % set all properties to their default values
            refreshProperties(this);
            
            % now overwrite the default props with whatever was provided by the user
            for i = 1:2:length(varargin)
                this.(varargin{i}) = varargin{i+1};
            end
        end
    end
    
    %% Private methods
    methods (Access = private)
        function createObjectInFigure(this, parent)
            % create the JComboBox first so that it appears hidden behind the textbox
            [jComboBox, hComboBox] = javacomponent(javax.swing.JComboBox, [], parent);
            
            % now create the search field so that it sits on top of the combobox
            jTextField = javax.swing.JTextField;
            [jTextField, hTextField] = javacomponent(jTextField, [], parent);
            
            % update object state
            this.jTextField = jTextField; %#ok<*PROPLC,*PROP>
            this.hTextField = hTextField;     
            this.jComboBox = jComboBox; 
            this.hComboBox = hComboBox;
            
            % setup keypress callback functions
            jTextHCallback = handle(jTextField,'CallbackProperties');
            set(jTextHCallback, 'KeyPressedCallback', @(src,evnt) keyRoutingFcn(this, src, evnt));
            
            this.Parent = parent;
        end
        
        function keyRoutingFcn(this, ~, evnt)
            modifiers = get(evnt, 'Modifiers'); % 1 = shift, 2 = ctrl, 8 = alt.  sum for combinations
            if ~ismember(modifiers, [0 1]) % only allows no modifier or shift to pass through
                return; % prevents trigger on CTRL+C/V/A
            end
            
            keyCode = get(evnt,'ExtendedKeyCode');
            
            switch keyCode
                case 10 % ENTER will select the current item from the jComboBox
                    setSelectedItem(this);
                    notify(this, 'EnterKeyPress');
                case 27 % ESC hides the popup
                    this.jComboBox.hidePopup;
                case {38 40} % UP/DOWN ARROW scrolls through jComboBox suggestions
                    if ~this.jComboBox.PopupVisible
                        this.jComboBox.showPopup;
                        return;
                    end
                    
                    selectedIndex = int32(this.jComboBox.SelectedIndex);
                    
                    if keyCode == 38
                        % UP ARROW: move selection up but don't let it go negative
                        selectedIndex = selectedIndex - 1;
                        selectedIndex(selectedIndex < 0) = 0;
                    else
                        % DOWN ARROW: move the selection down & prevent exceeding length of list
                        itemCount = this.jComboBox.ItemCount;
                        selectedIndex = selectedIndex + 1;
                        selectedIndex(selectedIndex > (itemCount-1)) = itemCount-1;
                    end
                    
                    this.jComboBox.setSelectedIndex(selectedIndex);
                otherwise
                    autoComplete(this)
            end
        end
        
        function autoComplete(this)
            textInput = this.String;
            textInput = strrep(textInput, '*', '.*'); % turn wildcards into valid regexp
            
            % try to match the typed text to the completion list
            if this.CaseSensitive
                matchedText = regexp(this.CompletionList, textInput, 'match','once');
            else
                matchedText = regexpi(this.CompletionList, textInput, 'match','once');
            end
            
            matchIndex = ~cellfun('isempty', matchedText);
            
            if ~any(matchIndex)
                this.jComboBox.hidePopup;
            end
            
            % highlight the matched text in the popup
            matchedText = matchedText(matchIndex);
            matchList = this.CompletionList(matchIndex);
            matchList = strrep(matchList, matchedText, strcat('<b><font color=blue>', matchedText, '</b></font>'));
            matchList = strcat('<html>',matchList,'</html>');
            
            try
                this.jComboBox.setModel(javax.swing.DefaultComboBoxModel(matchList));
                this.jComboBox.showPopup;
            catch ex
            end
            
            this.Matches = matchIndex;
        end
        
        function setSelectedItem(this, ~, ~) % give it 2 extra args so that it can be a callback
            if any(this.Matches) && this.jComboBox.PopupVisible
                selectedText = char(this.jComboBox.getSelectedItem);
                selectedText = regexprep(selectedText, '<[^>]+>', '');
                this.jTextField.setText(selectedText);
                this.jComboBox.hidePopup;
            end
        end
        
        function refreshProperties(this)
            props = properties(this);
            for i = 1:length(props)
                try
                    % setter functions actually apply the changes
                    this.(props{i}) = this.(props{i});
                end
            end
        end
    end
    
    %% Accessors (getters)
    methods
        function string = get.String(this)
            string = char(this.jTextField.getText);
        end
    end
    
    %% Accessors (setters)
    methods
        function set.BackgroundColor(this, value)
            p = inputParser;
            addRequired(p, 'BackgroundColor', ...
                @(x) validateattributes(x, {'numeric'},{'vector','numel',3,'>=',0,'<=',255}));
            parse(p, value); % this is only to generate errors
            
            % java colors are 8-bit ints, so convert to correct format & set props
            bckgColor = uint8(p.Results.BackgroundColor);
            jColor = java.awt.Color(bckgColor(1), bckgColor(2), bckgColor(3));
            this.jTextField.setBackground(jColor);
            this.BackgroundColor = bckgColor;
        end
        
        function set.CaseSensitive(this, value)
            p = inputParser;
            addRequired(p, 'CaseSensitive', @(x) validateattributes(x, {'logical','numeric'},{'scalar','binary'}));
            parse(p, value); % this is only to generate errors
            
            this.CaseSensitive = logical(value);
        end
        
        function set.Enabled(this, value)
            p = inputParser;
            addRequired(p, 'Enabled', @(x) validateattributes(x, {'logical','numeric'},{'scalar','binary'}));
            parse(p, value); % this is only to generate errors
            
            enableState = logical(value);
            this.jTextField.setEnabled(enableState);
            this.jComboBox.setEnabled(enableState);
            this.Enabled = enableState;
        end
        
        function set.FontColor(this, value)
            p = inputParser;
            addRequired(p, 'FontColor', ...
                @(x) validateattributes(x, {'numeric'},{'vector','numel',3,'>=',0,'<=',255}));
            parse(p, value); % this is only to generate errors
            
            % java colors are 8-bit ints, so convert to correct format & set props
            fontColor = uint8(value);
            jColor = java.awt.Color(fontColor(1), fontColor(2), fontColor(3));
            this.jTextField.setForeground(jColor);
            this.FontColor = fontColor;
        end
        
        function set.FontSize(this, value)
            p = inputParser;
            addRequired(p, 'FontSize', ...
                @(x) validateattributes(x, {'numeric'},{'scalar','nonnan','positive'}));
            parse(p, value); % this is only to generate errors
            
            fontSize = this.jTextField.getFont.deriveFont(value);
            this.jTextField.setFont(fontSize);
            this.FontSize = value;
        end
        
        function set.FontWeight(this, value)
            p = inputParser;
            addRequired(p, 'FontWeight', @(x) ischar(validatestring(x, {'normal','bold'})));
            parse(p, value); % this is only to generate errors
            
            fontWeight = lower(value);
            switch fontWeight
                case 'normal'
                    jFont = this.jTextField.getFont.deriveFont(uint8(java.awt.Font.PLAIN));
                case 'bold'
                    jFont = this.jTextField.getFont.deriveFont(uint8(java.awt.Font.BOLD));
            end
            this.jTextField.setFont(jFont);
            this.FontWeight = fontWeight;
        end
        
        function set.HorizontalAlignment(this, value)
            p = inputParser;
            addRequired(p, 'HorizontalAlignment',...
                @(x) ischar(validatestring(x, {'left','center','right'})));
            parse(p, value); % this is only to generate errors
            
            jAlignment = javax.swing.JTextField.(upper(value));
            this.jTextField.setHorizontalAlignment(jAlignment);
            this.HorizontalAlignment = alignment;
        end
        
        function set.Parent(this, value)
            set(this.hComboBox, 'Parent', value); %#ok<*MCSUP>
            set(this.hTextField, 'Parent', value);
            this.Parent = value;
        end
        
        function set.Position(this, value)
            p = inputParser;
            addRequired(p, 'Position', @(x) validateattributes(x, {'numeric'},{'vector','numel',4}));
            parse(p, value); % this is only to generate errors
            
            set(this.hComboBox, 'Position', value);
            set(this.hTextField, 'Position', value);
            this.Position = value;
        end
        
        function set.String(this, value)
            p = inputParser;
            addRequired(p, 'String', @(x) validateattributes(x, {'char','string'}, {}));
            parse(p, value); % this is only to generate errors
            
            textString = char(value);
            this.jTextField.setText(textString);
            this.String = textString;
        end
        
        function set.TooltipString(this, value)
            p = inputParser;
            addRequired(p, 'TooltipString', @(x) validateattributes(x, {'char','string'},{}));
            parse(p, value); % this is only to generate errors
            
            tooltip = char(value);
            this.jTextField.setToolTipText(tooltip);
            this.TooltipString = tooltip;
        end
        
        function set.Units(this, value)
            p = inputParser;
            addRequired(p, 'Units',@(x) ischar(validatestring(x,{'pixels','normalized','points'})));
            parse(p, value); % this is only to generate errors
            
            % apply the new units to the containers of both java objects
            units = lower(char(value));
            set(this.hTextField, 'Units', units);
            set(this.hComboBox, 'Units', units);
        end
        
        function set.Visible(this, value)
            p = inputParser;
            addRequired(p, 'Visible', @(x) validateattributes(x, {'logical','numeric'},{'scalar','binary'}));
            parse(p, value); % this is only to generate errors
            
            visibleState = logical(value);
            this.jTextField.setVisible(visibleState);
            this.jComboBox.setVisible(visibleState);
            this.Visible = visibleState;
        end
    end
end

