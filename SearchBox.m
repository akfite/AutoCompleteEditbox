classdef SearchBox < matlab.mixin.SetGet
    %SEARCHBOX An editbox with a built-in auto-complete feature.
    %   h = SearchBox(prop, value, ...) creates an editbox as a child of
    %   PARENT with 
    
    properties
        BackgroundColor = [255 255 255]
        CaseSensitive = false
        CompletionList = {'sample string'; 'test string'; 'sample test'}
        Enabled     = true
        FontSize    = 12
        FontWeight  = 'normal'
        FontColor   = [0 0 0]
        HorizontalAlignment = 'left'
        MatchFontColor = [0 0 255]
    end
    properties (SetAccess = protected)
        Matches % i want the prop list alphabetical and i'm not eager to overload disp()...
    end
    properties
        MaximumRowCount = 8
        Parent      = [] % default is really gcf but let's avoid calling gcf until args are parsed
        Position    = [20 20 200 26]
        String      = ''
        TooltipString = ''
        Units       = 'pixels'
        UserData    = []
        Visible     = true
    end
    
    properties (Access = protected)
        jTextField
        hTextField
        jComboBox
        hComboBox
    end
    
    events (NotifyAccess = protected)
        EnterKeyPressed % notifies any time enter is pressed
        ItemSelected % notifies when something is chosen from the list
    end
    
    %% Constructor
    methods
        function this = SearchBox(varargin)
            params = getInitialConfiguration(this, varargin{:});
            
            % create the uicontrols with jTextField and jComboBox defaults
            createObjectInFigure(this, params.parent);
            
            % initialize settings for the SearchBox wrapper class
            props = flipud(fieldnames(params)); % flipud ensures 'Units' goes before 'Position'
            for i = 1:length(props)
                prop = props{i};
                set(this, prop, params.(prop));
            end
        end
    end
    
    %% Private methods
    methods (Access = private)
        function createObjectInFigure(this, parent)
            % create the JComboBox first so that it appears hidden behind the textbox
            jComboBox = javaObjectEDT(javax.swing.JComboBox);
            [jComboBox, hComboBox] = javacomponent(jComboBox, [], parent);
            
            % now create the search field so that it sits on top of the combobox
            jTextField = javaObjectEDT(javax.swing.JTextField);
            [jTextField, hTextField] = javacomponent(jTextField, [], parent);
            
            % update object state
            this.jTextField = jTextField; %#ok<*PROPLC,*PROP>
            this.hTextField = hTextField;     
            this.jComboBox = jComboBox; 
            this.hComboBox = hComboBox;
            
            % setup keypress callback functions
            jTextHCallback = handle(jTextField,'CallbackProperties');
            set(jTextHCallback, 'KeyPressedCallback', @(src,evnt) keyRoutingFcn(this, src, evnt));
        end
        
        function keyRoutingFcn(this, ~, evnt)
            modifiers = get(evnt, 'Modifiers'); % 1 = shift, 2 = ctrl, 8 = alt.  sum for combinations
            if ~ismember(modifiers, [0 1]) % only allows no modifier & shift to pass through
                return; % prevents trigger on CTRL+C/V/A
            end
            
            keyCode = get(evnt,'ExtendedKeyCode');
            selectedIndex = int32(this.jComboBox.SelectedIndex);

            switch keyCode
                case 10 % ENTER will select the current item from the jComboBox
                    notify(this, 'EnterKeyPressed');
                    if this.jComboBox.PopupVisible
                        setSelectedItem(this);
                        notify(this, 'ItemSelected');
                    end
                case 27 % ESC hides the popup
                    this.jComboBox.hidePopup;
                case {33 36} % PAGE UP, HOME
                    if this.jComboBox.popupVisible
                        this.jComboBox.setSelectedIndex(0);
                    end
                case {34 35} % PAGE DOWN, END
                    if this.jComboBox.popupVisible
                        this.jComboBox.setSelectedIndex(this.jComboBox.ItemCount-1);
                    end
                case {38 40} % UP/DOWN ARROW scrolls through jComboBox suggestions
                    if (~this.jComboBox.PopupVisible) && (any(this.Matches) || isempty(this.String))
                        this.jComboBox.showPopup;
                        return;
                    end
                    
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
                case {16 20 37 39 127 155} 
                    % NO ACTION TAKEN -- don't try to autocomplete non-alphabet chars
                    % this list includes: shift, caps lock, left arrow, right arrow, delete, insert
                otherwise
                    autoComplete(this)
            end
        end
        
        function autoComplete(this)
            textInput = this.String;
            
            if isempty(textInput)
                % when the input is empty, 
                try
                    this.jComboBox.setModel(javax.swing.DefaultComboBoxModel(this.CompletionList));
                    this.jComboBox.showPopup;
                catch ex
                    warning(ex.message);
                end
                
                return
            end
            
            % turn wildcards into valid regexp
            textInput = strrep(textInput, '*', '.*');
            
            % try to match the typed text to the completion list
            if this.CaseSensitive
                matchedText = regexp(this.CompletionList, textInput, 'match','once');
            else
                matchedText = regexpi(this.CompletionList, textInput, 'match','once');
            end
            
            this.Matches = ~cellfun('isempty', matchedText);
            
            % color the parts of the text that match in the popup and show the popupMenu
            if any(this.Matches)
                matchedText = matchedText(this.Matches);
                matchList = this.CompletionList(this.Matches);
                matchFormatted = strcat(...
                    sprintf('<b><font color="rgb(%d,%d,%d)">',this.MatchFontColor), ...
                    matchedText, ...
                    '</b></font>');
                matchList = strrep(matchList, matchedText, matchFormatted);
                matchList = strcat('<html>',matchList,'</html>');

                try
                    this.jComboBox.setModel(javax.swing.DefaultComboBoxModel(matchList));
                    this.jComboBox.showPopup;
                catch ex
                    warning(ex.message)
                end
            else
                this.jComboBox.hidePopup;
            end
        end
        
        function setSelectedItem(this, ~, ~) % give it 2 extra args so that it can be a callback
            if this.jComboBox.PopupVisible
                selectedText = char(this.jComboBox.getSelectedItem);
                selectedText = regexprep(selectedText, '<[^>]+>', '');
                this.jTextField.setText(selectedText);
                this.jComboBox.hidePopup;
            end
        end
        
        function paramStruct = getInitialConfiguration(this, varargin)
            if isempty(varargin)
                params = {};
            else
                % check that varargin is formatted correctly (parmeter/value pairs)
                if mod(length(varargin),2)
                    error('All input arguments must be param/value pairs.');
                elseif any(~cellfun(@ischar, varargin(1:2:end)))
                    error('All param inputs must be of type char.');
                end
                
                varargin(1:2:end) = lower(varargin(1:2:end)); % all lowercase makes life ez
                params = varargin(1:2:end);
                values = varargin(2:2:end);
            end
            
            props = lower(properties(this));
            
            if any(~ismember(params, props))
                iBadParam = find(~ismember(params, props),1,'first');
                error('''%s'' is not a property of class %s.', params{iBadParam}, class(this));
            end 
            
            p = inputParser;
            
            % add the default props to the input parser list
            for i = 1:length(props)
                prop = props{i};
                switch prop
                    case 'string'
                        % 'String' is a special case because it requires the editbox to exist
                        addOptional(p, 'string', '');
                    case 'parent'
                        % default is 'gcf', but that can spawn a new figure inadvertently...
                        % so we're going to cheat and check ahead that 'parent is in in 
                        % the arg list before setting 'gcf' as the default
                        iParentParam = ismember('parent', params);
                        if sum(iParentParam) == 1
                            parentDefault = values{iParentParam};
                        else
                            % 'parent' not found in arg list: safe to use gcf
                            parentDefault = gcf;
                        end
                        addOptional(p, 'parent', gcf);
                    case 'matches'
                        continue % protected prop
                    otherwise
                        addOptional(p, prop, get(this, prop))
                end
            end
            parse(p,varargin{:});
            paramStruct = p.Results;
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
            if ischar(value)
                value = localConvertColorSpecToRGB(value);
            end
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
        
        function set.CompletionList(this, value)
            p = inputParser;
            addRequired(p, 'CompletionList', @(x) validateattributes(x, {'cell','string'},{}));
            parse(p, value); % this is only to generate errors
            
            % force type to be a cellstr column vector
            if isa(value, 'string')
                value = {value{:}}'; % convert to cellstr
            elseif isa(value, 'cell') && isrow(value)
                value = value';
            end
                
            this.CompletionList = unique(value);
            this.CompletionList = this.CompletionList(~cellfun(@isempty, this.CompletionList));
            % sort by lowercase alphabetical
            [~, isort] = sort(lower(this.CompletionList));
            this.CompletionList = this.CompletionList(isort);
            % apply change to the jComboBox
            this.jComboBox.setModel(javax.swing.DefaultComboBoxModel(this.CompletionList));
            this.jComboBox.hidePopup;
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
            if ischar(value)
                value = localConvertColorSpecToRGB(value);
            end
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
            this.HorizontalAlignment = value;
        end
        
        function set.MatchFontColor(this, value)
            if ischar(value)
                value = localConvertColorSpecToRGB(value);
            end
            p = inputParser;
            addRequired(p, 'MatchFontColor', ...
                @(x) validateattributes(x, {'numeric'},{'vector','numel',3,'>=',0,'<=',255}));
            parse(p, value); % this is only to generate errors
            
            % this is set via html so we don't NEED int types, but do it to stay consistent
            this.MatchFontColor = uint8(value);
        end
        
        function set.MaximumRowCount(this, value)
            p = inputParser;
            addRequired(p, 'MaximumRowCount', ...
                @(x) validateattributes(x, {'numeric'},{'scalar','nonnan','positive','integer'}));
            parse(p, value); % this is only to generate errors
            
            this.jComboBox.setMaximumRowCount(value);
            this.MaximumRowCount = value;
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

function RGB = localConvertColorSpecToRGB(colorspec)
    switch colorspec
        case {'y','yellow'}
            RGB = [1 1 0];
        case {'m','magenta'}
            RGB = [1 0 1];
        case {'c','cyan'}
            RGB = [0 1 1];
        case {'r','red'}
            RGB = [1 0 0];
        case {'g','green'}
            RGB = [0 1 0];
        case {'b','blue'}
            RGB = [0 0 1];
        case {'w','white'}
            RGB = [1 1 1];
        case {'k','black'}
            RGB = [0 0 0];
        otherwise
            error('''%s'' is not a MATLAB ColorSpec.', colorspec);
    end
    RGB = RGB * 255;
end