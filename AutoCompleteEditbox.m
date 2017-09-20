classdef AutoCompleteEditbox < matlab.mixin.SetGet
    %AUTOCOMPLETEEDITBOX Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = protected)
        BackgroundColor = [0.94 0.94 0.94]
        Enable      = true
        FontAngle   = 'normal'
        FontName    = 'Helvetica'
        FontSize    = 10
        FontWeight  = 'normal'
        HorizontalAlignment = 'left'
        Parent      = []
        Position    = [60 60 200 26]
        String      = ''
        Tag         = ''
        Units       = 'pixels'
        UserData    = []
        Visible     = true
    end
    
    properties (SetAccess = protected) % TODO: change to protected (set & get)
        jSearchField
        hSearchField
        jComboBox
        hComboBox
    end
    
    %% Constructor
    methods
        function this = AutoCompleteEditbox(varargin)
            createObjectInFigure(this);
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
            jSearchField = com.mathworks.widgets.SearchTextField;
            [jSearchField, hSearchField] = javacomponent(jSearchField.getComponent);
            
            % update object state
            this.jSearchField = jSearchField; %#ok<*PROP>
            this.hSearchField = hSearchField;
            this.jComboBox = jComboBox; 
            this.hComboBox = hComboBox;
        end
    end
end

