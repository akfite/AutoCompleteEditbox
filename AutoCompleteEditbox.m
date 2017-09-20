classdef AutoCompleteEditbox < matlab.mixin.SetGet
    %AUTOCOMPLETEEDITBOX Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
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
    
    %% Accessors
    methods (Access = private)
        function linkedSetterFcn(this, prop, value)
            % would prefer to use a linkprop but doesn't seem to be supported for java objects
            set(this.hComboBox, prop, value);
            set(this.hSearchField, prop, value);
        end
    end
    
    methods
        function set.BackgroundColor(this, value)
        end
        
        function set.Enable(this, value)
        end
        
        function set.FontAngle(this, value)
        end
        
        function set.FontName(this, value)
        end
        
        function set.FontSize(this, value)
        end
        
        function set.FontWeight(this, value)
        end
        
        function set.HorizontalAlignment(this, value)
        end
        
        function set.Parent(this, value)
            linkedSetterFcn(this, 'Parent', value)       
        end
        
        function set.Position(this, value)
            linkedSetterFcn(this, 'Position', value)
        end
        
        function set.String(this, value)
        end
        
        function set.Tag(this, value)
        end
        
        function set.Units(this, value)
        end
        
        function set.UserData(this, value)
        end
        
        function set.Visible(this, value)
        end
    end
end

