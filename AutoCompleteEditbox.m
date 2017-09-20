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
        Position    = [20 20 200 26]
        String      = ''
        Tag         = ''
        UserData    = []
        Visible     = true
    end
    
    properties (SetAccess = protected) % TODO: change to protected (set & get)
        jSearchText
        hSearchText
        jComboBox
        hComboBox
    end
    
    %% Constructor
    methods
        function this = AutoCompleteEditbox()
        end
    end
    
    %% Public interface
    methods
    end
    
    %% Private methods
    methods (Access = private)
    end
end

