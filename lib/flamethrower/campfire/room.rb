module Flamethrower
  module Campfire
    class Room
      include Flamethrower::Campfire::RestApi

      attr_reader :stream, :token
      attr_accessor :messages, :number, :name, :topic, :users

      def initialize(domain, token, params = {})
        @domain = domain
        @token = token
        @messages = Queue.new
        @number = params['id']
        @name = params['name']
        @topic = params['topic']
        @users = []
      end

      def fetch_room_info
        response = campfire_get("/room/#{@number}.json")
        json = JSON.parse(response.body)
        json['room']['users'].each do |user|
          @users << Flamethrower::Campfire::User.new(user)
        end
      end

      def connect
        @stream = Twitter::JSONStream.connect(:path => "/room/#{@number}/live.json", 
                                    :host => "streaming.campfirenow.com", 
                                    :auth => "#{@token}:x")
      end

      def store_messages
        @stream.each_item do |item| 
          params = JSON.parse(item)
          params['user'] = @users.first {|u| u.number == params['user']['id'] }
          params['room'] = self
          @messages << Flamethrower::Campfire::Message.new(params)
        end
      end

      def retrieve_messages
        Array.new.tap do |new_array|
          until @messages.empty?
            new_array << @messages.pop
          end
        end
      end

      def to_irc
        name = "##{@name.downcase.gsub("\s", "_")}"
        @irc_channel ||= Flamethrower::Irc::Channel.new(name)
        @irc_channel.users = @users.map(&:to_irc)
        @irc_channel
      end
    end
  end
end
