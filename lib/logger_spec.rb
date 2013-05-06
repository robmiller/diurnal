require 'logger'

include Diurnal

test_db = File.dirname(__FILE__) + "/../test/test.db"

# Zero the file before running our tests
File.open(test_db, 'w') { |f| f.write("") }

describe Logger do
  before :each do
    @logger = Logger.new(test_db)
  end

  describe "#initialize" do
    it "reads from a database file" do
      @logger.file.should == test_db
      @logger.db.should be_an_instance_of(SQLite3::Database)
    end
  end

  describe "#installed" do
    it "installs its tables" do
      @logger.installed?.should == true
    end
  end

  describe "#log" do
    it "logs new entries" do
      latest_id = @logger.latest_id
      @logger.log "test", 15.5
      @logger.latest_id.should_not == latest_id
    end
  end

  describe "#get_latest" do
    it "retrieves the latest entry" do
      @logger.get_latest("test").should == 15.5
    end
  end

  describe "#get_all" do
    it "retrieves all entries" do
      @logger.log "test", 20
      @logger.log "test", 25.5
      all = @logger.get_all "test"
      all.should include([Date.today.to_s, 15.5])
      all.should include([Date.today.to_s, 20])
      all.should include([Date.today.to_s, 25.5])
    end
  end
end
