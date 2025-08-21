Locales = json.decode(LoadResourceFile(Config.Resource, ('locales/%s.json'):format(Config.Lang)))

if not Locales then
    print(('Could not load locales/%s.json'):format(Config.Lang))

    Locales = json.decode(LoadResourceFile(Config.Resource, ('locales/en.json')))
end
