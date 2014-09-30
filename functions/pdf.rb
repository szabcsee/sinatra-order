#!/bin/env ruby
# encoding: utf-8

def render_form(data, url, company_name, company_address, wholesaler)
# This is the data structure that the form render require for the orders
#
#        product name  5% min order           5% ordered        10% min ordered     10% ordered
# data = [['Product name' ,'Min order amount 5',  'Ordered 5%', 'Min order amount 10', 'Ordered 10%'],
#   ['Product1'  ,   '2',            '10',   '4',            '5'],
#   ['Product2'  , '2',            '15',   '4',            '20'],
#   ['Product3' , '2',            '10',   '4',            '5']]
#The above is just an example of the data structure what the pdf creator (Prawn) can digest.

    path = url.to_s
    Prawn::Document.generate(path, :page_size => 'A4', :margin => [30,30,40,50], :info => {  # Document size 595.28 x 841.89
      :Title    => "Order Form",
      :Author   => "Company",
      :Subject  => "Successful order",
      :Producer => "digitalyogis",
      :Creation => Time.now }) do |pdf|
      #  font_normal_path =
      #  font_bold_path =
      #  font_italic_path =
      #  pdf.font_families.update("Futura" => { :normal => "public/fonts/DejaVuLGCSans.ttf",
      #                                         :italic => "public/fonts/DejaVuLGCSans-Oblique.ttf",
      #                                         :bold => "public/fonts/DejaVuLGCSans-Bold.ttf"})
      # The fonts have been removed but it is recommended that you use your own fonts.
        pdf.image("public/images/company-logo.png", { :position => :left, :vposition => :top, :scale => 0.25})
        pdf.image("public/images/company-title.png", { :position => :right, :vposition => :top, :scale => 0.24, :top_margin => 30})
        pdf.text "#{company_name}".upcase + "/" + "#{company_address} | Selected wholesaler: #{wholesaler} ".upcase, :size => 9, :align => :left
        pdf.move_up 11
        pdf.move_down 20
        pdf.stroke_color "818285"
        pdf.stroke_horizontal_rule
        pdf.move_down 10
        pdf.fill_color "2cb45b"
        pdf.text "Our items can be ordered individually!", :size => 19, :align => :center, :character_spacing => 4.1
        pdf.move_down 15
          pdf.table( data, :header => true,
                           :cell_style => { :size => 8,
                                            :overflow => :shrink_to_fit,
                                            :align => :center,
                                            :text_color => "242424",
                                            :border_colors => ["2cb45b","2cb45b","2cb45b","2cb45b"]},
                           :width => 510) do |table|
            table.row(0).size = 9
            table.row(0).font_style = :bold
            table.column(0).width = 260
            table.column(1).width = 65
            table.column(2).width = 65
            table.column(3).width = 65
            table.column(1).borders = [:top, :bottom]
            table.column(1).border_colors = "FFFFFF"
            table.column(1).background_color = "2cb45b"
            table.column(1).overflow = :shrink_to_fit
            table.column(1).text_color = "FFFFFF"
            table.column(3).borders = [:top, :bottom]
            table.column(3).border_colors = "FFFFFF"
            table.column(3).background_color = "2cb45b"
            table.column(3).overflow = :shrink_to_fit
            table.column(3).text_color = "FFFFFF"
          end
        pdf.move_down 10
        pdf.text "Legal stuff can come here"
    end
    return true
end