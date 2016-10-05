Configuration ServerCore {

    import-DSCresource -ModuleName PSDesiredStateConfiguration
           
        WindowsFeature ServerCore
        {
            Ensure = "Absent"
            Name = "User-Interfaces-Infra"
            IncludeAllSubFeature = $false
        } 
                                                              
    }