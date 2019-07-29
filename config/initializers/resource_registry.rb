ResourceRegistry.configure do 
  {
    registry: {
      config: {
        name: "public",
        default_namespace: "core",
        root: '.',
        system_dir: "system",
        auto_register: []
      },
      load_paths: ['system']
    },
    options: {
      key: :tenants,
      namespaces:[
        {
          key: :dchbx,
          namespaces: [{
            key: :persistence,
            settings: [
              { key: :store, default: 'file_store' },
              { key: :serializer, default: 'yaml_serializer' },
              { key: :container, default: 'config' }
            ]
          }]
        }
      ]
    }
    # options: {
    #   tenants: [ :dchbx, :cca ],
    #   dchbx: {
    #     persistence:{
    #       store: "file_store",
    #       serializer: "yaml_serializer",
    #       container: "config"
    #     }
    #   },
    #   cca: {}
    # }
  }
end

Kernel.const_set("Registry", ResourceRegistry::PublicRegistry)
ResourceRegistry.const_set(:PublicInject, Registry.injector)
require_relative Rails.root.join('system', 'boot')