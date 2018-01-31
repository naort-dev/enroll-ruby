module TransportProfiles
  class Steps::CreateFile < Steps::Step

    def initialize(path, contents, gateway)
      super("Create file: #{path}", gateway)
      @path = path
      @contents = contents
    end

    def execute
      File.write(@path, @contents)
    end


  end
end
