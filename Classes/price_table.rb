require 'csv'

class PriceTable
  attr_reader :main_table, :size, :debug
  attr_accessor :industry_split, :industry_map, :company_table

  def initialize(args = nil)
    @company_table = CompanyTable.new
    @main_table = {}
    @industry_split = {}
    @size = 0
    @debug = args && args[:debug]
    load
  end

  def add(item)
    begin
      new_id = (item.cid + '$' + item.period.to_s).to_sym
    rescue
      binding.pry
    end
    main_table[new_id] = item
    @size += 1
  end

  def subset(args)
    raise 'Trying to use PriceTable#subset without Industry arg... Don\'t have join table to do that...' if !args[:industry]
    industry_split[args[:industry]].select { |k, v| 
                (v.period == args[:period] &&
                v.market_cap >= args[:cap_floor] &&
                v.market_cap <= args[:cap_ceiling] &&
                v.price < 1000 &&
                v.delisted == FALSE &&
                v.ltm_ebit != 0 &&
                v.earnings_yield != 0 &&
                v.range_52 > 0 &&
                v.range_52 <= args[:range_52_cap]) }.map { |k, v| v }
  end

  def where(args)
    industry_split[industry_map[args[:cid]]]["#{args[:cid]}$#{args[:period]}".to_sym]
  end

  def keys
    main_table.keys
  end

  def first
    main_table[keys.first]
  end

  def last
    main_table[keys.last]
  end

  def all_periods(args=nil)
    range = (args && args[:debug]) ? (2005..2006) : (2005..2015)
    result = []
    range.each do |year|
      (1..12).each { |month| result << "#{year}-#{"%02d" % month}-01" }
    end
    result
  end

  def all_industries
    company_table.all_industries
  end

  private

  def load
    puts '--------------------------------------------------------'
    puts 'Loading data...'
    start_time = Time.now
    load_companies
    load_industry_partitions
    load_industry_map
    puts "All data loaded! Time spent: #{(Time.now - start_time).round(2)} seconds."
    puts '--------------------------------------------------------'
  end

  def load_companies
    @company_table = Marshal.load File.open("Data/companies.marsh", 'rb').read
    puts 'Company data loaded!'
  end

  def load_industry_partitions
    industries = all_industries
    result = {}
      for i in 1..8 do
        puts "Loading price and fundamental data for #{industries[i - 1]}..."
        if debug
          result[industries[i - 1]] = Marshal.load File.open("Data/ind_#{i}_short.marsh", 'rb').read
        else
          result[industries[i - 1]] = Marshal.load File.open("Data/ind_#{i}_full.marsh", 'rb').read
        end
      end
    result['index'] = Marshal.load File.open("Data/ind_9_full.marsh", 'rb').read
    @industry_split = result
    puts 'All price and fundamental data loaded!'
  end

  def load_industry_map
    result = {}
    company_table.main_table.each do |k, v|
      result[k] = v.sector
    end
    puts 'Industry mapping loaded!'
    @industry_map = result
  end


  def build_industry_datafiles
  # optional, use when need to rebuild industry source files
    industries = all_industries
    industries << 'index'
    for i in (1..9) do
      puts "Processing #{industries[i-1]}..."
      this_industry_cids = company_table.industry_subset(industries[i - 1])
      temp_subset = main_table.select{ |k, v| this_industry_cids.include?(v.cid) }
      filename = "ind_#{i}_short.marsh"
      File.open(filename, 'wb') {|f| f.write(Marshal.dump(temp_subset)) }
      puts "#{industries[i-1]} saved to #{filename}."
    end
  end

  def build_from_csv
  # constructs PriceTable from CSV files
  # takes over 2 min to run on 2005-2015 data
  # Safe Mode required to save Marshal files
  # currently the fully constructed instance is loaded from Marshal files (~14 sec to load)
  # use it only to re-build the PriceTable instance when needed

    puts '--------------------------------------------------------'
    puts 'Loading data...'
    start_time = Time.now
    periods = []
    (2005..2006).each do |year|
      (1..12).each { |month| periods << "#{month}/1/#{year}" }
    end

    # (1..2).each do |part|
      CSV.foreach("data_m_2005-06.csv", headers: true, encoding: 'ISO-8859-1') do |row|
        for i in 0..periods.size - 1
          ocf_ltm = row[i * 15 + 14].to_f.round(3)
          ocf_minus_1 = row[i * 15 + 15].to_f.round(3)
          ocf_minus_2 = row[i * 15 + 16].to_f.round(3)

          new_entry_fields = {
            cid: row[2],
            period: (Date.strptime(periods[i], '%m/%d/%Y')).to_s,
            price: row[i * 15 + 8].to_f.round(2),
            # low_52: row[i * 15 + 9].to_f.round(2),
            # high_52: row[i * 15 + 10].to_f.round(2),
            ev: row[i * 15 + 11].to_f.round(3),
            ltm_ebit: row[i * 15 + 12].to_f.round(3),
            # ltm_ebitda: row[i * 15 + 13].to_f.round(3),
            ocf_ltm: ocf_ltm,
            ocf_minus_1: ocf_minus_1,
            ocf_minus_2: ocf_minus_2,
            net_ppe: row[i * 15 + 17].to_f.round(3),
            nwc: row[i * 15 + 18].to_f.round(3),
            market_cap: row[i * 15 + 19].to_f.round(3),
            range_52: row[i * 15 + 20].to_f.round(3),
            roc: row[i * 15 + 21].to_f.round(3),
            earnings_yield: row[i * 15 + 22].to_f.round(3),
            ocf_3yr_yield: row[i * 15 + 11].to_f > 0 ? ((ocf_ltm + ocf_minus_1 + ocf_minus_2) / row[i * 15 + 11].to_f).round(3) : 0,
            delisted: (row[6] == 'index' ? true : false) }
          delisted_check = /(\d+\/\d+\/\d+)/.match(row[i * 15 + 8])
          if delisted_check
            new_entry_fields[:delisted] = true
            new_entry_fields[:delisting_date] = (Date.strptime(delisted_check[1], '%m/%d/%Y')).to_s
          end
          new_entry = PricePoint.new(new_entry_fields) if new_entry_fields[:delisting_date] != ''
          self.add(new_entry)

          $stdout.sync = true
          print "   #{((size / 822756.0) * 100).round(1).to_s}% complete; #{comma_separated(size)} out of 822,756 entries added\r" if size % 1000 == 0
        end   # all PricePoints for this CID filled
        company_table.add(Company.new(name: row[0], cid: row[2], sector: row[6]))
      end  # all PricePoints filled
    # end

    puts ''
    puts '--------------------------------------------------------'
    puts "Data loaded! Time spent: #{(Time.now - start_time).round(2)} seconds."
    binding.pry

    # these lines to manually test memory sufficiency for read/write
    # File.open('test.marsh', 'wb') {|f| f.write(Marshal.dump(self)) }
    # test_read = Marshal.load File.open('test.marsh', 'rb').read
  end
end
