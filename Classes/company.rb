class Company
  attr_accessor :name, :cid, :sector

  def initialize(args)
    @name = args[:name]
    @cid = args[:cid]
    @sector = args[:sector]
  end
end
