return {

    ----------------------------------------------
    --        💬 Setup logging system
    ----------------------------------------------

    logs = {
        -- What logging service do you want to use?
        -- Available options: 'fivemanage', 'fivemerr', 'discord' & 'none'
        -- It is highly recommended to use a proper logging service such as Fivemanage or Fivemerr
        service = 'discord',
        -- Do you want to include screenshots with your logs?
        -- This is only applicable to Fivemanage and Fivemerr
        screenshots = false,
        -- You can enable (true) or disable (false) specific player events to log here
        events = {
            -- register_robbed is when a register has been robbed
            register_robbed = true,
            -- safe_robbed is when.. come on now, you gotta know..
            safe_robbed = true
        },
        -- If service = 'discord', you can customize the webhook data here
        -- If not using Discord, this section can be ignored
        discord = {
            -- The name of the webhook
            name = 'LOGS Robbery Warung',
            -- The webhook link
            link = 'https://discord.com/api/webhooks/1406541255290257469/DBnyGzJXjwHYrKVBSgiVlo9gbzylXdG8BxhS1hKfCwybB7EtwlM4XWXoj7wyelFKdseC',
            -- The webhook profile image
            image = 'https://i.imgur.com/ILTkWBh.png',
            -- The webhook footer image
            footer = 'https://i.imgur.com/ILTkWBh.png'
        }
    }

}