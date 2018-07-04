Adminium = lukkit.addPlugin( "Adminium", "1.0-beta",
  function( plugin )
    plugin.onEnable(
      function()

        plugin.print( "Loading..." )
        server:dispatchCommand( server:getConsoleSender(), "mvdelete Game")
        server:dispatchCommand( server:getConsoleSender(), "mvconfirm")

        plugin.config.setDefault( "config.playerLimit", 8 )
        plugin.config.setDefault( "config.noOceans", true )
        plugin.config.setDefault( "config.noDeserts", true )
        plugin.config.setDefault( "config.noMountains", false )
        plugin.config.setDefault( "config.noJungle", false )
        plugin.config.setDefault( "config.largeBiomes", true )
        plugin.config.save()

        if plugin.config.get( "config.playerLimit" ) > 8 then
          plugin.config.set( "config.playerLimit", 8 )
          plugin.print("Error: Cannot have more than 8 players in a game")
        end

      end
    )

    -- >> Plugin Disabling Process:
    --    * Delete old game if it exists

    plugin.onDisable(
      function()

        if game then
          server:broadcast("§cError: §7Game existed on plugin shutdown.", "adminium.info")
        end
        deleteGame(game)
        server:broadcast("§6Caution: §7Plugin is now disabled", "adminium.info")

      end
    )

    -- >> New Game Function
    --    * Generate new world using Multiverse
    --    * Configure world properties for pre-start

    function newGame( options )
      local temp = {}
      if plugin.config.get("config.largeBiomes") == true then
        server:dispatchCommand( server:getConsoleSender(), "mvc Game normal -t largebiomes" )
      else
        server:dispatchCommand( server:getConsoleSender(), "mvc Game normal")
      end

      temp.stage = "CREATING"
      temp.creator = options.creator
      temp.gameType = options.gameType or "NORMAL"
      temp.border = 800
      temp.open = false
      temp.members = {}
      temp.warps = {}

      server:dispatchCommand( server:getConsoleSender(), "mvm set respawnWorld Game Game")
      server:dispatchCommand( server:getConsoleSender(), "mvm set hunger false Game")
      server:dispatchCommand( server:getConsoleSender(), "mvm set difficulty 0 Game")
      server:dispatchCommand( server:getConsoleSender(), "mvm set bedRespawn false Game")
      server:dispatchCommand( server:getConsoleSender(), "mv gamerule doDaylightCycle false Game")
      server:dispatchCommand( server:getConsoleSender(), "mvm set time 6000 Game")

      local world = server:getWorld("Game")
      local border = world:getWorldBorder()
      border:setCenter(0.0, 0.0)
      border:setDamageAmount(0.2)
      border:setSize(800.0)
      border:setWarningTime(30)

      return temp
    end

    function deleteGame( temp )
      temp = nil
      server:dispatchCommand( server:getConsoleSender(), "mvdelete Game")
      server:dispatchCommand( server:getConsoleSender(), "mvconfirm")
      return temp
    end

    function isPlayer( temp, name )
      if not temp.members then error("Attempted to get member of non existent game") end

      for i = 1, #temp.members do
        if string.upper(temp.members[i]) == string.upper(name) then
          return true
        end
      end
      return false
    end

    function removePlayer( name )
      local removed = false
      print("Remove "..name)
      for i = 1, #game.members do
        print(tostring(i).." "..tostring(game.members[i]))
        if game.members[i] == name then
          table.remove(game.members, i)
          return true
        end
      end
      return false
    end

    function addPlayer( temp, name )
      if not isPlayer( temp, name ) and ( #temp.members < plugin.config.get("config.playerLimit") or 8 ) then
        table.insert( temp.members, name )
        return true
      else
        return false
      end
    end

    function startGame( game, isTest )
      if isTest == true then
        broadcast("§6Caution: §7The game is being tested!")
      else
        broadcast("§2Notice: §7Game is starting!")
      end
      local world = server:getWorld("Game")
      deathWorld = world
      server:dispatchCommand( server:getConsoleSender(), "mvm set gamemode 0 Game")
      server:dispatchCommand( server:getConsoleSender(), "mv gamerule doDaylightCycle true Game")
      server:dispatchCommand( server:getConsoleSender(), "mvm set time 0 Game")
      server:dispatchCommand( server:getConsoleSender(), "mvm set difficulty 2 Game")
      if isTest == true then
        server:dispatchCommand(server:getConsoleSender(), "delay 30 s game shrink start test")
      else
        server:dispatchCommand(server:getConsoleSender(), "delay 30 m game alert halfway")
        server:dispatchCommand(server:getConsoleSender(), "delay 30 m game shrink start")
      end
      local players = {}
      for n = 1, #game.members do
        players[n] = server:getOfflinePlayer(game.members[n])
        local pos = world:getSpawnLocation()
        pos:setX( game.warps[n].x )
        pos:setZ( game.warps[n].z )
        pos:setY( world:getHighestBlockYAt(pos:getX(), pos:getZ()) + 1.5 )
        print("x="..pos:getX().." y="..pos:getY().." z="..pos:getZ())
        players[n]:teleport( pos )
        server:dispatchCommand( server:getConsoleSender(), "gamemode survival "..players[n]:getName())

        players[n]:setFoodLevel(20)
        players[n]:setSaturation(20.0)
        players[n]:setPlayerListName("§a"..players[n]:getName().."§r")
        players[n]:setDisplayName("§a"..players[n]:getName().."§r")
        players[n]:setHealth(players[n]:getMaxHealth())
        players[n]:getInventory():clear()
      end
    end

    function checkWarpSafety( temp )
      local unsafeBiomes = {}
      if plugin.config.get("config.noOceans") == true then
        table.insert(unsafeBiomes, "FROZEN_OCEAN")
        table.insert(unsafeBiomes, "OCEAN")
        table.insert(unsafeBiomes, "DEEP_OCEAN")
      end
      if plugin.config.get("config.noDeserts") == true then
        table.insert(unsafeBiomes, "DESERT")
        table.insert(unsafeBiomes, "DESERT_HILLS")
      end
      if plugin.config.get("config.noMountains") == true then
        table.insert(unsafeBiomes, "EXTREME_HILLS")
        table.insert(unsafeBiomes, "EXTREME_HILLS_MOUNTAINS")
        table.insert(unsafeBiomes, "EXTREME_HILLS_PLUS")
        table.insert(unsafeBiomes, "EXTREME_HILLS_PLUS_MOUNTAINS")
      end
      if plugin.config.get("config.noJungle") == true then
        table.insert(unsafeBiomes, "JUNGLE")
        table.insert(unsafeBiomes, "JUNGLE_EDGE")
        table.insert(unsafeBiomes, "JUNGLE_HILLS")
        table.insert(unsafeBiomes, "JUNGLE_MOUNTAINS")
      end


      plugin.print("There are "..#unsafeBiomes.." restricted biomes")

      for i = 1, #temp.warps do
        server:getWorld("Game"):loadChunk( temp.warps[i].x, temp.warps[i].z, true )
      end

      for warp = 1, #temp.warps do
        local biome = server:getWorld("Game"):getBiome(temp.warps[warp].x, temp.warps[warp].z)
        plugin.print(warp..": " .. tostring(biome))
        for b = 1, #unsafeBiomes do
          -- Biome check
          if tostring(biome) == tostring(unsafeBiomes[b]) then return true, warp, tostring(biome) end
        end
        -- Block safety check
        local surfaceblock = server:getWorld("Game"):getBlockAt( temp.warps[warp].x, server:getWorld("Game"):getHighestBlockYAt(temp.warps[warp].x, temp.warps[warp].z)-1, temp.warps[warp].z )
        surfaceblock:setTypeId(7)
      end
      local unsafeBiomes = {
        "FROZEN_OCEAN",
        "OCEAN",
        "DEEP_OCEAN",
        "RIVER",
      }
      local biome = server:getWorld("Game"):getBiome(0, 0)
      plugin.print("Spawn: " .. tostring(biome))
      for b = 1, #unsafeBiomes do
        if tostring(biome) == tostring(unsafeBiomes[b]) then return true, "Spawn", tostring(biome) end
      end
      local blocks = {
        {0, 0, 7, 0},
        {0, 0, 7, 1},
        {0, 1, 98, 0},
        {0, -1, 98, 0},
        {1, 0, 98, 0},
        {1, 1, 98, 0},
        {1, -1, 98, 0},
        {-1, 0, 98, 0},
        {-1, 1, 98, 0},
        {-1, -1, 98, 0},
        {0, 1, 54, 1},
        {1, 0, 54, 1},
        {-1, 0, 54, 1},
        {0, -1, 54, 1},
        {0, 0, 145, 2},
        {0, 0, 7, -1},
        {0, 0, 7, -2}
      }
      local y = server:getWorld("Game"):getHighestBlockYAt(0,0)-1
      for i = 1, #blocks do
        local surfaceblock = server:getWorld("Game"):getBlockAt( blocks[i][1], y + ( blocks[i][4] or 0 ), blocks[i][2] )
        surfaceblock:setTypeId(blocks[i][3])
      end

      return false
    end

    function addWarps( temp )
      local world = server:getWorld("Game")
      if not world then error("Cannot add warps to a non existant world") return end
      local coords = {
        {300,300},
        {-300,-300},
        {-300,300},
        {300,-300},
        {0,300},
        {0,-300},
        {300,0},
        {-300,0},
      }
      for c = 1, #coords do
        temp.warps[c] = {}
        temp.warps[c].x = coords[c][1] + 0.5
        temp.warps[c].z = coords[c][2] + 0.5
        temp.warps[c].y = world:getHighestBlockYAt(coords[c][1], coords[c][2]) + 1
      end
      return temp
    end

    plugin.addCommand( "game", "Main command for managing the different games.", "/game help",
      function( sender, args )
        if ( args[1] == "version" or args[1] == "ver" ) and sender:hasPermission("adminium.game.version") then

          sender:sendMessage("§aVersion: §7Adminium " .. plugin.version .." by Lord_Cuddles")

        elseif ( not args[1] or args[1] == "help" or args[1] == "?" ) and sender:hasPermission("adminium.game.help") then

          local entries = {
            "§e/game help [page=1] §7- Show a list of commands",
            "§e/game info §7- Show game information",
            "§e/game create [params..] §7- Create a new game",
            "§e/game version §7- Show game version",
            "§e/game start §7- Teleports everyone to their starts",
            "§e/game check [warp] §7- Check the world and warps",
            "§e/game open §7- Allows joining the game",
            "§e/game close §7- Prevent further joining",
            "§e/game config [value|help] §7- Change game config",
          }
          local title = "§6#>-------<# §fAdminium §6#>-------<#"
          local page = tonumber(args[2]) or 1
          sender:sendMessage( title )
          for entry = (page * 8) - 7, (page * 8) do
            if entries[entry] then
              sender:sendMessage(entries[entry])
            elseif entry == #entries + 1 then
              sender:sendMessage("§7There are no more entries to display")
            end
          end

        elseif ( args[1] == "info" or args[1] == "i" ) and sender:hasPermission("adminium.game.info") then

          if not game then
            sender:sendMessage("§cError: §7A game does not exist")
          else
            sender:sendMessage("§6#>-------<# §fGame Info §6#>-------<#")
            sender:sendMessage("§eCreated by: §7" .. game.creator )
            local pfx = "§7"
            if game.stage == "RUNNING" then pfx = "§a" end
            if game.stage == "WAITING" then pfx = "§6" end
            if game.stage == "OVER" then pfx = "§3" end
            if game.stage == "JOINING" then pfx = "§d" end
            sender:sendMessage("§eCurrent stage: " .. pfx .. game.stage )
            sender:sendMessage("§eGame type: §7" .. game.gameType )
            if #game.members < 2 then
              sender:sendMessage("§eMembers ("..#game.members.."/"..plugin.config.get("config.playerLimit").."): §c"..table.concat( game.members, "§7, §c"))
            elseif #game.members == plugin.config.get("config.playerLimit") then
              sender:sendMessage("§eMembers ("..#game.members.."/"..plugin.config.get("config.playerLimit").."): §a"..table.concat( game.members, "§7, §a"))
            else
              sender:sendMessage("§eMembers ("..#game.members.."/"..plugin.config.get("config.playerLimit").."): §7"..table.concat( game.members, "§7, §f"))
            end
          end

        elseif ( args[1] == "create" or args[1] == "new" or args[1] == "+" ) and sender:hasPermission("adminium.game.create") then

          if game then
            sender:sendMessage("§cError: §7A game already exists")
          else

            broadcast("§6Caution: §7Generating worlds. Lag will occur...")
            local attempts = 1
            repeat
              game = newGame( { creator = sender:getName() } )
              game = addWarps( game )
              local unsafeWarp, unsafe, biome = checkWarpSafety( game )
              if unsafeWarp then
                sender:sendMessage("§cError: §7Attempt "..attempts.." Failed: Warp "..unsafe.." is "..biome)
                attempts = attempts + 1
                game = deleteGame( game )
              end
            until not unsafeWarp or attempts > 3

            if attempts > 3 then sender:sendMessage("§4Critical: §7All seeds were incompatible") return end
            plugin.print("Took "..attempts.." to create compatible world")
            sender:sendMessage("§aSuccess: §7You have created a new game")
            server:dispatchCommand( server:getConsoleSender(), "mvm set gamemode spectator Game")
            server:dispatchCommand( server:getConsoleSender(), "mvtp "..sender:getName().." Game")
            game.stage = "WAITING"

          end

        elseif ( args[1] == "delete" or args[1] == "remove" or args[1] == "-" ) and sender:hasPermission("adminium.game.delete") then


          game = deleteGame( game )
          sender:sendMessage("§aSuccess: §7You have removed any existing games")

        elseif ( args[1] == "add" or args[1] == "join" or args[1] == "j" ) and sender:hasPermission("adminium.game.add") then

          if not game then
            sender:sendMessage("§cError: §7A game does not exist") return
          end
          if not game.open then
            sender:sendMessage("§cError: §7Game not accepting invitations") return
          end
          if not args[2] then
            sender:sendMessage("§6Usage: §7/game add [username]") return
          end

          local player = server:getOfflinePlayer(args[2])
          if not player:isOnline() then
            sender:sendMessage("§cError: §7That player is not online")
          else
            if addPlayer( game, player:getName() ) then
              sender:sendMessage("§aSuccess: §7Added "..player:getName().." to the game")
              player:sendMessage("§eInfo: §7You have been added to the game")
              if #game.members >= 2 then
                game.stage = "READY"
              else
                game.stage = "JOINING"
              end
            else
              sender:sendMessage("§cError: §7You cannot add that player")
            end
          end

        elseif ( args[1] == "kick" or args[1] == "k" ) and sender:hasPermission("adminium.game.kick") then

          if not game then
            sender:sendMessage("§cError: §7A game does not exist") return
          end
          if not args[2] then
            sender:sendMessage("§6Usage: §7/game kick [username]") return
          end
          local player = server:getOfflinePlayer(args[2])
          if removePlayer( player:getName() ) then
            if player:isOnline() then
              player:sendMessage("§4Critical: §7You have been kicked from the game")
            end
            sender:sendMessage("§aSuccess: §7You have kicked "..player:getName().." from the game")
            if #game.members >= 2 then
              game.stage = "READY"
            elseif game.open then
              game.stage = "JOINING"
            else
              game.stage = "WAITING"
            end
          else
            sender:sendMessage("§cError: §7"..player:getName().." is not in the game")
          end

        elseif ( args[1] == "start" ) and sender:hasPermission("adminium.game.start") then
          if not game then sender:sendMessage("§cError: §7A game does not exist") return end
          if game.stage == "READY" then
            game.open = false
            game.stage = "RUNNING"
            if args[2] == "test" or args[2] == "isTest" then isTest = true end
            startGame( game, isTest )
          else
            sender:sendMessage("§cError: §7Cannot start game until ready")
          end

        elseif ( args[1] == "check" ) and sender:hasPermission("adminium.game.check") then

          if not game then sender:sendMessage("§cError: §7A game does not exist") return end
          if game.stage ~= "RUNNING" then
            if not args[2] then
              sender:sendMessage("§6Usage: §7/game check [warp]")
              return
            end
            args[2] = tonumber(args[2])
            if args[2] < 1 or args[2] > #game.warps then
              sender:sendMessage("§cError: §7This warp does not exist")
            else
              local pos = server:getWorld("Game"):getSpawnLocation()
              pos:setX( game.warps[args[2]].x )
              pos:setZ( game.warps[args[2]].z )
              pos:setY( server:getWorld("Game"):getHighestBlockYAt(pos:getX(), pos:getZ()) + 1.5 )
              sender:teleport( pos )
              sender:sendMessage("§eInfo: §7You are viewing start "..args[2])
            end
          else
            sender:sendMessage("§cError: §7You cannot check warps now")
          end

        elseif ( args[1] == "open" ) and sender:hasPermission("adminium.game.open") then

          game.open = true
          game.stage = "JOINING"
          broadcast("§eInfo: §7Game is now open to join")
          sender:sendMessage("§aSuccess: §7Game is now open to join")

        elseif ( args[1] == "close" ) and sender:hasPermission("adminium.game.open") then

          game.open = false
          broadcast("§eInfo: §7Game is no longer open to join")
          sender:sendMessage("§aSuccess: §7Game is no longer open to join")

        elseif ( args[1] == "config" ) and sender:hasPermission("adminium.game.config") then

          if args[2] == "playerLimit" then
            if not args[3] then
              sender:sendMessage("§eInfo: §7playerLimit = " ..plugin.config.get("config.playerLimit"))
            else
              if tonumber(args[3]) > 1 and tonumber(args[3]) <= 8 then
                sender:sendMessage("§aSuccess: §7Set playerLimit to "..args[3])
                plugin.config.set("config.playerLimit", tonumber(args[3]))
                plugin.config.save()
              else
                sender:sendMessage("§cError: §7Must be an integer: 2 - 8")
              end
            end
          elseif args[2] == "noOceans" then
            if not args[3] then
              sender:sendMessage("§eInfo: §7noOceans = " ..plugin.config.get("config.noOceans"))
            else
              if args[3] == "true" or args[3] == "false" then
                sender:sendMessage("§aSuccess: §7Set noOceans to "..args[3])
                if args[3] == "true" then
                  plugin.config.set("config.noOceans", true)
                elseif args[3] == "false" then
                  plugin.config.set("config.noOceans", false)
                end
                plugin.config.save()
              else
                sender:sendMessage("§cError: §7Must be a boolean value")
              end
            end
          elseif args[2] == "noDeserts" then
            if not args[3] then
              sender:sendMessage("§eInfo: §7noDeserts = " ..plugin.config.get("config.noDeserts"))
            else
              if args[3] == "true" or args[3] == "false" then
                sender:sendMessage("§aSuccess: §7Set noDeserts to "..args[3])
                if args[3] == "true" then
                  plugin.config.set("config.noDeserts", true)
                elseif args[3] == "false" then
                  plugin.config.set("config.noDeserts", false)
                end
                plugin.config.save()
              else
                sender:sendMessage("§cError: §7Must be a boolean value")
              end
            end
          elseif args[2] == "noMountains" then
            if not args[3] then
              sender:sendMessage("§eInfo: §7noMountains = " ..plugin.config.get("config.noMountains"))
            else
              if args[3] == "true" or args[3] == "false" then
                sender:sendMessage("§aSuccess: §7Set noMountains to "..args[3])
                if args[3] == "true" then
                  plugin.config.set("config.noMountains", true)
                elseif args[3] == "false" then
                  plugin.config.set("config.noMountains", false)
                end
                plugin.config.save()
              else
                sender:sendMessage("§cError: §7Must be a boolean value")
              end
            end
          elseif args[2] == "largeBiomes" then
            if not args[3] then
              sender:sendMessage("§eInfo: §7largeBiomes = " ..plugin.config.get("config.largeBiomes"))
            else
              if args[3] == "true" or args[3] == "false" then
                sender:sendMessage("§aSuccess: §7Set largeBiomes to "..args[3])
                if args[3] == "true" then
                  plugin.config.set("config.largeBiomes", true)
                elseif args[3] == "false" then
                  plugin.config.set("config.largeBiomes", false)
                end
                plugin.config.save()
              else
                sender:sendMessage("§cError: §7Must be a boolean value")
              end
            end
          elseif args[2] == "noJungle" then
            if not args[3] then
              sender:sendMessage("§eInfo: §7noJungle = " ..plugin.config.get("config.noJungle"))
            else
              if args[3] == "true" or args[3] == "false" then
                sender:sendMessage("§aSuccess: §7Set noJungle to "..args[3])
                if args[3] == "true" then
                  plugin.config.set("config.noJungle", true)
                elseif args[3] == "false" then
                  plugin.config.set("config.noJungle", false)
                end
                plugin.config.save()
              else
                sender:sendMessage("§cError: §7Must be a boolean value")
              end
            end
          elseif args[2] == "help" or args[2] == "list" or not args[2] then
            sender:sendMessage("§6Usage: /game config [option] [value]")
            sender:sendMessage("§eplayerLimit: §f"..plugin.config.get("config.playerLimit"))
            sender:sendMessage("§enoOceans: §f"..tostring(plugin.config.get("config.noOceans")))
            sender:sendMessage("§enoDeserts: §f"..tostring(plugin.config.get("config.noDeserts")))
            sender:sendMessage("§enoMountains: §f"..tostring(plugin.config.get("config.noMountains")))
            sender:sendMessage("§enoJungle: §f"..tostring(plugin.config.get("config.noJungle")))
            sender:sendMessage("§elargeBiomes: §f"..tostring(plugin.config.get("config.largeBiomes")))
          else
            sender:sendMessage("§cError: §7Unknown config value, try /game config help")
          end

        elseif args[1] == "alert" and sender == server:getConsoleSender() then
          if not game then sender:sendMessage("§cError: §7A game does not exist") return end
          if args[2] == "halfway" then
            broadcast("§6Caution: §715 minutes before the border shrinks.")
          elseif args[2] == "shrunk" then
            broadcast("§6Caution: §7The border has finished shrinking!")
          elseif args[2] == "thanks" then
            broadcast("§aGame Over: §7Thank you for playing!")
          else
            sender:sendMessage("§6Usage: §7/game alert [halfway|shrunk]")
          end

        elseif args[1] == "shrink" and sender:hasPermission("adminium.game.shrink") then
          if not game then sender:sendMessage("§cError: §7A game does not exist") return end
          if not game.running then sender:sendMessage("§cError: §7The game is not running") end
          if args[2] == "start" then
            broadcast("§6Caution: §7The border is now shrinking! Head to 0, 0 or perish.")
            local world = server:getWorld("Game")
            local border = world:getWorldBorder()
            border:setDamageBuffer(0.0)
            if args[3] == "test" then
              border:setSize(64.0, 30)
            else
              border:setSize(64.0, 180)
            end
            server:dispatchCommand(server:getConsoleSender(), "mvm set difficulty 3")
          elseif args[2] == "reset" then
            broadcast("§eInfo: §7The border has been reset")
            local world = server:getWorld("Game")
            local border = world:getWorldBorder()
            border:setDamageBuffer(0.0)
            border:setSize(800.0)
          end

        else

          sender:sendMessage("§cError: §7That command does not exist")

        end

      end
    )

    plugin.addCommand("join", "Joins an active game", "/join",
      function( sender, args )
        if not game then
          sender:sendMessage("§cError: §7A game does not exist")
        elseif game.open == false then
          sender:sendMessage("§cError: §7The game cannot be joined now!")
        else
          if addPlayer( game, sender:getName() ) == true then
            if #game.members >= 2 then
              game.stage = "READY"
            else
              game.stage = "JOINING"
            end
            broadcast("§eInfo: §7"..sender:getName().." has joined position "..#game.members)
          else
            if isPlayer( game, sender:getName() ) then
              sender:sendMessage("§cError: §7You are already a member")
            else
              sender:sendMessage("§cError: §7This game is full")
              sender:sendMessage("§7You could join as a spectator? /spectate")
            end
          end
        end
      end
    )

    plugin.addCommand("leave", "Leave an active game", "/leave",
      function(sender, args)
        sender:sendMessage("§4Critical: §7Feature not implemented. Ask an admin for a kick")
      end
    )

    events.add("playerJoin",
      function( event )
        local player = event:getPlayer()
        if not game or game.stage ~= "RUNNING" then
          player:setDisplayName("§e"..player:getName().."§r")
          player:setPlayerListName("§e"..player:getName().."§r")
          server:dispatchCommand(server:getConsoleSender(), "clear "..player:getName())
        end
      end
    )

    events.add("playerRespawn",
      function( event )
        if not game then return end
        if game.stage == "RUNNING" or game.stage == "OVER" then
          local player = event:getPlayer():getName()
          server:dispatchCommand(server:getConsoleSender(), "gamemode 3 "..player)
        end
      end
    )

    events.add("playerDeath",
      function( event )
        if not game then return end
        if game.stage == "RUNNING" then
          local player = event:getEntity():getPlayer()
          local location = player:getLocation()
          event:getEntity():getPlayer():getWorld():strikeLightningEffect( location )
          event:setDeathMessage(event:getEntity():getPlayer():getDisplayName().." §cwas eliminated.")
          if removePlayer( player:getName() ) == true then
            if #game.members == 1 then
              broadcast("§b"..game.members[1].." §3wins the game! §bCongratulations!")
              local winner = server:getOfflinePlayer(game.members[1]):getPlayer()
              winner:setDisplayName("§eCHAMP§6"..winner:getName().."§r")
              winner:setPlayerListName("§6"..winner:getName().."§r")
              game.stage = "OVER"
              server:dispatchCommand(server:getConsoleSender(), "delay 30 s clear "..player:getName())
              server:dispatchCommand(server:getConsoleSender(), "delay 30 s game alert thanks")
              server:dispatchCommand(server:getConsoleSender(), "delay 30 s game delete")
            else
              server:broadcast("§c"..player:getName().." has died. "..#game.members.." remain!")
            end
            player:setDisplayName("§8DEAD:§7§o"..player:getName().."§r")
            player:setPlayerListName("§7§o"..player:getName().."§r")
          end
        end
      end
    )

  end
)
