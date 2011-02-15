module TDiary
  module Models
    class Diary
      include DataMapper::Resource

      property :date, String, :key => true
      property :title, String
      property :body, Text
      property :format, String
      property :visible, Boolean, :default => true
      property :last_modified, Time

      def self.date(yyyymmdd)
        self.get(yyyymmdd)
      end

      def self.month(yyyymm)
        self.all(:date.gte => "#{yyyymm}01", :date.lte => "#{yyyymm}31",
                 :order => :date)
      end

      # def body
      # diary = style( style_name )::new( headers['Date'], headers['Title'], body, Time::at( headers['Last-Modified'].to_i ) )
      # end

    end
  end
end
