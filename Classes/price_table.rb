require 'csv'

class PriceTable
  attr_reader :main_table, :size, :company_table

  def initialize
    binding.pry
    @main_table = {}
    @company_table = CompanyTable.new
    @size = 0
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
    main_table.select { |k, v| 
                      (v.period == args[:period] &&
                      v.market_cap >= args[:cap_floor] &&
                      v.market_cap <= args[:cap_ceiling] &&
                      v.price > 0 &&
                      v.price < 200000 &&
                      v.delisted == FALSE &&
                      v.ltm_ebit != 0 &&
                      v.roc != 0 &&
                      v.earnings_yield != 0) }.map { |k, v| v }
  end

  def where(args)
    main_table["#{args[:cid]}$#{args[:period]}".to_sym]
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
    # select(:period).map(&:period).uniq
    # if args[:single_period] == '1'
    #   start_date = Date.strptime(args[:start_date], '%Y-%m-%d')
    #   [start_date.to_s, (start_date+1.year).to_s]
    # else
    #   range = args[:development] == true ? (1993..2001).to_a : (1993..2014).to_a
    #   result = []
    #   range.each { |year| result << "#{year}-12-31" }
    #   result
    # end

    result = []
    if args[:debug]
      (2005..2006).each do |year|
        (1..12).each { |month| result << "#{year}-#{"%02d" % month}-01" }
      end
    else
      (2005..2015).each do |year|
        (1..12).each { |month| result << "#{year}-#{"%02d" % month}-01" }
      end
    end
    result
  end
  
  private

  # use #load only to re-build the source objects
  # takes over 2 min to load
  # save to Marshal only possible in Safe Mode (from 2005 only)
  # currently they are stored in a Marshal file (~14 sec)

  def load
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
          new_entry_fields = {
            cid: row[2],
            period: (Date.strptime(periods[i], '%m/%d/%Y')).to_s,
            price: row[i * 15 + 8].to_f.round(2),
            # low_52: row[i * 15 + 9].to_f.round(2),
            # high_52: row[i * 15 + 10].to_f.round(2),
            ev: row[i * 15 + 11].to_f.round(3),
            ltm_ebit: row[i * 15 + 12].to_f.round(3),
            # ltm_ebitda: row[i * 15 + 13].to_f.round(3),
            ocf_ltm: row[i * 15 + 14].to_f.round(3) > 0 ? '+' : '-',
            ocf_minus_1: row[i * 15 + 15].to_f.round(3) > 0 ? '+' : '-',
            ocf_minus_2: row[i * 15 + 16].to_f.round(3) >0 ? '+' : '-',
            net_ppe: row[i * 15 + 17].to_f.round(3),
            nwc: row[i * 15 + 18].to_f.round(3),
            market_cap: row[i * 15 + 19].to_f.round(3),
            range_52: row[i * 15 + 20].to_f.round(3),
            roc: row[i * 15 + 21].to_f.round(3),
            earnings_yield: row[i * 15 + 22].to_f.round(3),
            delisted: (row[6] == 'index' ? true : false) }
          delisted_check = /(\d+\/\d+\/\d+)/.match(row[i * 15 + 8])
          if delisted_check
            new_entry_fields[:delisted] = true
            new_entry_fields[:delisting_date] = (Date.strptime(delisted_check[1], '%m/%d/%Y')).to_s
          end
          new_entry = PricePoint.new(new_entry_fields) if new_entry_fields[:delisting_date] != ''
          self.add(new_entry)

          # confirm total count

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
