lib.registerConfig({
    config = {    
        ['BasicMarker'] = {
            type = 'bennys', -- não alterar
            input = 'bennys', -- não alterar
            -- Input configuration
            marker = { -- set custom marker if the type is marker
                id = 27, -- marker id = https://docs.fivem.net/docs/game-references/markers/
                color = {0,255,0,75}, -- marker color (R,G,B,A)
                scale = vec3(4.0, 4.0, 1.0),
                rotacao = vec3(0.0, 180.0, 130.0), -- marker Rotation (x,y,z)
                bobUpAndDown = false, -- marker bopUpAndDown
                faceCamera = false, -- marker faceCamera
                rotation = true, -- marker rotation
                custom = { -- Custom Marker
                    active = false,
                    dict = '',
                    name = ''
                }
            },
            actionKey = 38,
            -- Map Configuration
            blip = {
                name = 'Bennys', -- Name to display on the map!
                blipId = 73, -- blip id = https://docs.fivem.net/docs/game-references/blips/
                blipColor = 13, -- color id
                blipScale = 0.5, -- scale for blip
            }
        }
    },

    locs = {
        {showBlip = true, markerDistance = 50.0, distance = 3.0, coord = vector3(74.399809,-1095.939575,29.011410), heading = 359.29, config = 'BasicMarker'},
    },

    commands = {
        {showBlip = true, coord = vector3(-75.770088195801,-818.69323730469,326.17532348633), distance = 100000000, command = "openMarkerWithCommand", config = 'BasicMarker'},
    }
})