classdef AutoCompleteEditbox < matlab.mixin.SetGet
    %AUTOCOMPLETEEDITBOX Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        BackgroundColor = [255 255 255]
        CompletionList = {'sample string'; 'test string'; 'sample test'}
        Enabled     = true
        FontSize    = 10
        FontWeight  = 'normal'
        FontColor   = [0 0 0]
        HorizontalAlignment = 'left'
        Parent      = []
        Position    = [200 200 200 26]
        String      = ''
        Tag         = ''
        TooltipString = ''
        Units       = 'pixels'
        UserData    = []
        Visible     = true
    end
    
    properties (SetAccess = protected) % TODO: change to protected (set & get)
        jTextField
        hTextField
        jComboBox
        hComboBox
    end
    
    %% Constructor
    methods
        function this = AutoCompleteEditbox(varargin)
            % create the uicontrols
            createObjectInFigure(this);
            
            % parse args and apply properties to default if not provided
        end
    end
    
    %% Public interface
    methods
    end
    
    %% Private methods
    methods (Access = private)
        function createObjectInFigure(this)
            % create the JComboBox first so that it appears hidden behind the textbox
            [jComboBox, hComboBox] = javacomponent(javax.swing.JComboBox);
            
            % now create the search field so that it sits on top of the combobox
            jTextField = javax.swing.JTextField;
            [jTextField, hTextField] = javacomponent(jTextField);
            
            % update object state
            this.jTextField = jTextField; %#ok<*PROP>
            this.hTextField = hTextField;     
            this.jComboBox = jComboBox; 
            this.hComboBox = hComboBox;
            
            % DEBUG --------------------------------------------
            set(this.hTextField, 'position', this.Position);
            set(this.hComboBox, 'position', this.Position);
            % --------------------------------------------------
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
            parse(p, value);
            
            % java colors are 8-bit ints, so convert to correct format & set props
            bckgColor = uint8(p.Results.BackgroundColor);
            jColor = java.awt.Color(bckgColor(1), bckgColor(2), bckgColor(3));
            this.jTextField.setBackground(jColor);
            this.BackgroundColor = bckgColor;
        end
        
        function set.Enabled(this, value)
            p = inputParser;
            addRequired(p, 'Enabled', @(x) validateattributes(x, {'logical','numeric'},{'scalar','binary'}));
            parse(p, value);
            
            enableState = logical(p.Results.Enabled);
            this.jTextField.setEnabled(enableState);
            this.jComboBox.setEnabled(enableState);
            this.Enabled = enableState;
        end
        
        function set.FontColor(this, value)
            p = inputParser;
            addRequired(p, 'FontColor', ...
                @(x) validateattributes(x, {'numeric'},{'vector','numel',3,'>=',0,'<=',255}));
            parse(p, value);
            
            % java colors are 8-bit ints, so convert to correct format & set props
            fontColor = uint8(p.Results.FontColor);
            jColor = java.awt.Color(fontColor(1), fontColor(2), fontColor(3));
            this.jTextField.setForeground(jColor);
            this.FontColor = fontColor;
        end
        
        function set.FontSize(this, value)
        end
        
        function set.FontWeight(this, value)
        end
        
        function set.HorizontalAlignment(this, value)
            p = inputParser;
            addRequired(p, 'HorizontalAlignment',...
                @(x) ischar(validatestring(x, {'left','center','right'})));
            parse(p, value);
            
            alignment = p.Results.HorizontalAlignment;
            jAlignment = javax.swing.JTextField.(upper(alignment));
            this.jTextField.setHorizontalAlignment(jAlignment);
            this.HorizontalAlignment = alignment;
        end
        
        function set.Parent(this, value)
            set(this.hComboBox, 'Parent', value); %#ok<*MCSUP>
            set(this.hTextField, 'Parent', value);
        end
        
        function set.Position(this, value)
            set(this.hComboBox, 'Position', value);
            set(this.hTextField, 'Position', value);
        end
        
        function set.String(this, value)
            p = inputParser;
            addRequired(p, 'String', @(x) validateattributes(x, {'string','char'}, {}));
            parse(p, value);
            
            textString = char(value);
            this.jTextField.setText(textString);
            this.String = textString;
        end
        
        function set.Tag(this, value)
        end
        
        function set.TooltipString(this, value)
            p = inputParser;
            addRequired(p, 'TooltipString', @(x) validateattributes(x, {'char'},{'vector'}));
            parse(p, value);
            
            this.jTextField.setToolTipText(char(value));
        end
        
        function set.Units(this, value)
        end
        
        function set.UserData(this, value)
        end
        
        function set.Visible(this, value)
        end
    end
end

