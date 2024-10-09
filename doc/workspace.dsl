/*
 * This is a comment block
 *
 */
// This is also a comment
workspace {
    !const CODENAME "testarossa"

    !docs ./README.md
    !docs ./docs
    !adrs ./adrs

    model {
        properties {
            "structurizr.groupSeparator" "/"
        }

        // System Components/Actors
        u = person "User"
        //   softwareSystem      name         [description]    [tags] 
        xd = softwareSystem "Xilica Designer" "Desktop software 
        xc = softwareSystem "Xilica Cloud"
        tr = softwareSystem "${CODENAME}" {
            // wa = container "Web Application"
            // db = container "Database Schema" {
            //     # tag container element to enable styling later 
            //     tags "Database"
            // }
            // som = group "SoM" {
            //     linux = softwareSystem "Linux"
            //     awe = softwareSystem "AudioWeaver"
            // }
            // io = group "IO"
        }
        
        // User Interactions
        u -> xd "Uses"
        u -> xc "Uses"
        // System Interactions
        xd -> tr "HTTPS"
        xc -> tr "HTTPS"
    }
    views {
        systemContext tr "SystemContextView" {
            include *
            // autolayout tb  
        }
        // container tr "ContainerView" {
        //     include *
        //     autolayout tb
        // }
        styles {
            element "Person" {
                color #ffffff
                background #666666
                fontSize 22
                shape Person
            }
            element "Customer" {
                background #08427b
            }
            element "Bank Staff" {
                background #999999
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Existing System" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Web Browser" {
                shape WebBrowser
            }
            element "Mobile App" {
                shape MobileDeviceLandscape
            }
            element "Database" {
                shape Cylinder
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Failover" {
                opacity 25
            }
        }
        # styles {
        #     # sets the foreground colour of all elements to white
        #     element "Element" {
        #         color white
        #     }
        #     # sets the background colour of all software systems to green
        #     element "Software System" {
        #         background #2D882D
        #     }
        #     # sets the background colour of all people to a darker green
        #     # sets the shape of all people to a person shape
        #     element "Person" {
        #         background #116611
        #         shape person
        #     }
        #     # make all elements with "Database" tag a cylinder shape
        #     element "Database" {
        #         shape cylinder
        #     }
        #     # make all containers light green
        #     element "Container" {
        #         background #55aa55
        #     }
        # }
    }

    configuration {
        scope softwaresystem
    }

}
