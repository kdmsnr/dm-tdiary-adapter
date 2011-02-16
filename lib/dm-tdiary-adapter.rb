require 'rubygems'
require 'dm-core'

module DataMapper
  module Adapters
    class TdiaryAdapter < AbstractAdapter

      def create(resources)
        resources.each do |resource|
          date = resource.date
          case resource.model.to_s
          when "TDiary::Models::Diary"
            File.open(gen_path(date), "a+") do |f|
              next if resource.model.date(date)
              f.puts <<-EOS
TDIARY2.01.00
Date: #{date}
Title: #{resource.title}
Last-Modified:
Visible: #{resource.visible}
Format: #{resource.format}

#{resource.body}

.
EOS
            end
          end
        end
      end

      # returns Array of Hash
      def read(query)
        case query.model.to_s
        when "TDiary::Models::Diary"
          if id = extract_id_from_query(query)
            date = id
            limit = date
          else
            date = query.options.values[0] # TODO: handle more conditions
            limit = false
          end
          return parse_tdiary_file(gen_path(date), query.fields, limit)
        end
      end

      def update(attributes, collection)
        raise NotImplementedError, "#{self.class}#update not implemented"
      end

      def delete(collection)
        raise NotImplementedError, "#{self.class}#delete not implemented"
      end

      private
      def gen_path(date, ext = "td2")
        year = date[0, 4]
        month = date[4, 2]
        "#{options['path']}/#{year}/#{year}#{month}.#{ext}"
      end

      def extract_id_from_query(query)
        return nil if query.limit != 1

        conditions = query.conditions

        unless conditions.kind_of?(DataMapper::Query::Conditions::AndOperation)
          return nil
        end

        unless (key_condition = conditions.select { |o| o.subject.key? }).
            size == 1
          return nil
        end

        key_condition.first.value
      end

      def parse_tdiary_file(path, fields, date = nil)
        array = []
        File.open(path){|f|
          f.read
        }.split(/\r?\n\.\r?\n/).each do |l|
          attrs = []
          headers, body = parse_tdiary(l)
          next if date and headers['Date'] != date
          attrs << headers['Date']
          attrs << headers['Title']
          attrs << headers['Format'] || 'tDiary'
          attrs << headers['Visible'] == 'true'
          attrs << Time::at(headers['Last-Modified'].to_i)
          attrs << body
          array << fields.zip(attrs).to_hash
        end
        array
      end

      def parse_tdiary(data)
        header, body = data.split( /\r?\n\r?\n/, 2 )
        headers = {}
        if header then
          header.each do |l|
            l.chomp!
            key, val = l.scan( /([^:]*):\s*(.*)/ )[0]
            headers[key] = val ? val.chomp : nil
          end
        end
        if body then
          body.gsub!( /^\./, '' )
        else
          body = ''
        end
        [headers, body]
      end
    end
  end
end
