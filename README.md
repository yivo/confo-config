# ConfoConfig

## A little configuration DSL
```ruby
configuration do
  autocomplete_limit 20
  autocomplete_phrase_length 2

  i18n do
    available_locales [:en, :ru]
    default_locale :en
  end

  list do
    single_actions { can :update, :toggle, :delete, :preview }
    plural_actions { can :create, :filter, :export, :search }

    highlight { role admin: :red, user: :gray }

    configure(:column, :avatar) { type :photo }

    columns { include :name, :avatar, :role }
  end

  form do
    configure(:input, :avatar) { type :photo }
    actions { can :save, :cancel }
  end
end
```

## Gemfile
```ruby
gem 'confo-config', github: 'yivo/confo-config'
```