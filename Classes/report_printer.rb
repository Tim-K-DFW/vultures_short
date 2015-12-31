require 'axlsx'

class ReportPrinter
  attr_reader :results

  def initialize(results)
    @results = results
  end

  def generate
      Axlsx::Package.new do |p|
      wb = p.workbook
      generate_summary(wb)
      generate_positions(wb)
      p.serialize("Reports/#{filename}")
      return filename
    end
  end

  def filename
    p = results['parameters']
    "results-#{p['position_count']}@#{p['market_cap_floor']}-#{p['market_cap_ceiling']}.xlsx"
  end

  def generate_summary(wb)
    wb.add_worksheet(name: 'performance') do |s|
      regular_style = s.styles.add_style()
      italicized = s.styles.add_style(i: true, num_fmt: 8)
      table_title = s.styles.add_style(fg_color: '000000', bg_color: 'BDD4E8',
        b: true, alignment: { horizontal: :center, vertical: :center, wrap_text: true} )
      currency = s.styles.add_style(num_fmt: 8)
      percentage = s.styles.add_style(num_fmt: 10, alignment: { horizontal: :right })
      whole_percentage = s.styles.add_style(num_fmt: 9)
      s.sheet_view.show_grid_lines = false

      s.add_row []
      s.add_row ['','Strategy Performance'], sz: 18
      s.add_row []
      s.add_row ['','Parameters'], sz: 14
      s.add_row ['','Rebalance frequency', results['parameters']['rebalance_frequency']]
      s.add_row ['','# of positions in portfolio', results['parameters']['position_count']]
      s.add_row ['','Market cap floor, $mm', results['parameters']['market_cap_floor']]
      s.add_row ['','Market cap ceiling, $mm', results['parameters']['market_cap_ceiling']]
      s.add_row ['','Maximum % of 52-week range', results['parameters']['52_week_range_cap']]
      s.add_row []
      s.add_row ['','Scoring weights'], sz: 14
      s.add_row ['','(lowest values favored more when respective weight is positive)']
      s.add_row ['','Earnings yield', results['parameters']['weights']['earnings_yield']], style: whole_percentage
      s.add_row ['','% of 52-week range', results['parameters']['weights']['52_week_range']], style: whole_percentage
      s.add_row ['','3-year OCF yield', results['parameters']['weights']['ocf_3yr_yield']], style: whole_percentage
      s.add_row []
      s.add_row ['','By period'], sz: 14
      s.add_row ['','Period ending', 'Market value at period end', 'by period', '', 'by period, annualized',
                '', 'cumulative CY', '', 'rolling 12 months', ''], style: [nil, Array.new(10, table_title)].flatten
      s.add_row ['', '', '', Array.new(4, ['tested strategy', 'S&P 500'])].flatten,
                style: [nil, Array.new(10, table_title)].flatten
      s.add_row ['','Initial balance', results['parameters']['initial_balance']], style: italicized
      s.merge_cells('b18:b19')
      s.merge_cells('c18:c19')
      s.merge_cells('d18:e18')
      s.merge_cells('f18:g18')
      s.merge_cells('h18:i18')
      s.merge_cells('j18:k18')
      results['performance'].each { |period|
        s.add_row ['', period['date'], period['balance'],
                  period['by_period']['return'],
                  period['by_period']['sp500_return'],
                  period['annualized']['return'],
                  period['annualized']['sp500_return'],
                  period['cumulative_cy']['return'],
                  period['cumulative_cy']['sp500_return'],
                  period['rolling_12_months']['return'],
                  period['rolling_12_months']['sp500_return']],
                  style: [nil, nil, currency, Array.new(8, percentage)].flatten }
      s.add_row []
      s.add_row ['','Aggregated'], sz: 14
      s.add_row ['',"For the period between #{results['aggregated']['start_date']} and #{results['aggregated']['end_date']} "]
      s.add_row ['', '', 'tested strategy', 'S&P 500'], style: [nil, Array.new(3, table_title)].flatten
      results['aggregated']['table'].keys[0..4].each do |line|
        this_line = results['aggregated']['table'][line]
        s.add_row ['', this_line['description'], this_line['portfolio'], this_line['sp500']], style: [nil, nil, percentage, percentage]
      end
      this_line = results['aggregated']['table']['f_sharpe']
      s.add_row ['', 'Sharpe ratio', this_line['portfolio'], this_line['sp500']]
      s.column_widths 3, 43, 15, 11, 11, 11, 11, 11, 11, 11, 11
    end
  end

  def generate_positions(wb)
    wb.add_worksheet(name: 'positions') do |s|
      italicized = s.styles.add_style(i: true, num_fmt: 8)
      table_title = s.styles.add_style(fg_color: '000000', bg_color: 'BDD4E8', num_fmt: 8,
                  alignment: { horizontal: :center, vertical: :center, wrap_text: true} )
      table_total = s.styles.add_style(fg_color: '000000', bg_color: 'BDD4E8', num_fmt: 8)
      decimal_2 = s.styles.add_style(num_fmt: 4)
      delimiter = s.styles.add_style(num_fmt: 3)
      currency = s.styles.add_style(num_fmt: 7)
      currency_red = s.styles.add_style(num_fmt: 8)
      percentage = s.styles.add_style(num_fmt: 10)
      right_align = s.styles.add_style(alignment: { horizontal: :right} )
      s.sheet_view.show_grid_lines = false

      s.add_row []
      s.add_row ['','Holdings during each period'], sz: 18
      s.add_row []
      results['positions'].each do |period|
        s.add_row ['', period['end_date'] == '' ? "Current portfolio" : "Period ending #{period['end_date']}"], sz: 14
        s.add_row ['', 'Capital IQ ID','Company', 'Sector', 'Market cap', 'LTM EBIT', 'EV', 'Net PPE + NWC',
                  'Earnings Yield', '% of 52 week range', '3yr OCF yield', 'Shares', 'BEG price per share', 'BEG market value', 
                  period['end_date'] == '' ? ['', '', ''] : ['END Price per share', 'END market value', 'Profit'],
                  'Notes'].flatten,
                  style: [nil, Array.new(17, table_title)].flatten
        period['positions'].each { |position|
          s.add_row ['', position['cid'], position['company_name'], position['sector'],
                    position['market_cap'], position['ltm_ebit'], position['ev'],
                    position['capital'], position['earnings_yield'],
                    position['52_week_range'], position['ocf_3yr_yield'], position['share_count'],
                    position['beginning_price'], position['beginning_value'],
                    period['end_date'] == '' ? '' : position['ending_price'],
                    period['end_date'] == '' ? '' : position['ending_value'],
                    period['end_date'] == '' ? '' : position['profit'],
                    position['notes']],
                    style: [nil, nil, nil, nil, Array.new(4, decimal_2), percentage, percentage, percentage, delimiter, Array.new(4, currency), currency_red, right_align].flatten }
          s.add_row ['', 'Cash', Array.new(11, ''), period['cash'], '',
                    period['end_date'] == '' ? '' : period['cash'], '',
                    ''].flatten, style: italicized
          s.add_row ['', 'Total', Array.new(11, ''),
                    period['total_value_beginning'], '',
                    period['end_date'] == '' ? '' : period['total_value_ending'],
                    period['end_date'] == '' ? '' : period['total_profit'], ''].flatten,
                    style: [nil, Array.new(17, table_total)].flatten
          s.add_row []
      end
      s.column_widths 3, 11, 40, 25, 10, 10, 10, 10, 10, 10, 10, 10, 10, 16, 10, 16, 16, 22
    end
  end
end
