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
        function this = set.BackgroundColor(this, value) %#ok<*MCSV,*MCHM,*MCHV3>
            p = inputParser;
            addRequired(p, 'BackgroundColor', ...
                @(x) validateattributes(x, {'numeric'},{'vector','numel',3,'>=',0,'<=',255}));
            parse(p, value);
            
            % jSearch accepts 8-bit ints, so convert to correct format & set props
            bckgColor = uint8(p.Results.BackgroundColor);
            jColor = java.awt.Color(bckgColor(1), bckgColor(2), bckgColor(3));
            this.jTextField.setBackground(jColor);
            this.BackgroundColor = bckgColor;
        end
        
        function this = set.Enabled(this, value)
            p = inputParser;
            addRequired(p, 'Enabled', @(x) validateattributes(x, {'logical','numeric'},{'scalar','binary'}));
            parse(p, value);
            
            enableState = logical(p.Results.Enabled);
            this.jTextField.setEnabled(enableState);
            this.jComboBox.setEnabled(enableState);
            this.Enabled = enableState;
        end
        
        function this = set.FontColor(this, value)
            p = inputParser;
            addRequired(p, 'FontColor', ...
                @(x) validateattributes(x, {'numeric'},{'vector','numel',3,'>=',0,'<=',255}));
            parse(p, value);
            
            % jSearch accepts 8-bit ints, so convert to correct format & set props
            fontColor = uint8(p.Results.FontColor);
            jColor = java.awt.Color(fontColor(1), fontColor(2), fontColor(3));
            this.jTextField.setForeground(jColor);
            this.FontColor = fontColor;
        end
        
        function this = set.FontSize(this, value)
        end
        
        function this = set.FontWeight(this, value)
        end
        
        function this = set.HorizontalAlignment(this, value)
        end
        
        function this = set.Parent(this, value)
            set(this.hComboBox, 'Parent', value); %#ok<*MCSUP>
            set(this.hTextField, 'Parent', value);
        end
        
        function this = set.Position(this, value)
            set(this.hComboBox, 'Position', value);
            set(this.hTextField, 'Position', value);
        end
        
        function this = set.String(this, value)
        end
        
        function this = set.Tag(this, value)
        end
        
        function this = set.Units(this, value)
        end
        
        function this = set.UserData(this, value)
        end
        
        function this = set.Visible(this, value)
        end
    end
end

