class PricePoint
  attr_accessor :cid, :period, :market_cap, :net_ppe, :nwc, :ltm_ebit, :ev, :earnings_yield, :roc, :price, :delisted, :delisting_date, :low_52, :high_52, :range_52, :ltm_ebitda, :ocf_ltm, :ocf_minus_1, :ocf_minus_2

  def initialize(args)
    @cid = args[:cid]
    @period = args[:period]
    @price = args[:price]
    # @low_52 = args[:low_52]
    # @high_52 = args[:high_52]
    @ev = args[:ev]
    @ltm_ebit = args[:ltm_ebit]
    # @ltm_ebitda = args[:ltm_ebitda]
    @ocf_ltm = args[:ocf_ltm]
    @ocf_minus_1 = args[:ocf_minus_1]
    @ocf_minus_2 = args[:ocf_minus_2]
    @net_ppe = args[:net_ppe]    
    @nwc = args[:nwc]
    @market_cap = args[:market_cap]
    @range_52 = args[:range_52]
    @roc = args[:roc]
    @earnings_yield = args[:earnings_yield]
    @delisted = args[:delisted]
    @delisting_date = args[:delisting_date] || ''
  end

  def attributes   # review needed
    result = {}
    result["cid"] = cid
    result["period"] = period
    result["market_cap"] = market_cap
    result["net_ppe"] = net_ppe
    result["nwc"] = nwc
    result["ltm_ebit"] = ltm_ebit
    result["ev"] = ev
    result["earnings_yield"] = earnings_yield
    result["roc"] = roc
    result["price"] = price
    result
  end
end