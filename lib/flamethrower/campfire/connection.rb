module Flamethrower
  module Campfire
    class Connection
      attr_reader :token, :domain

      include Flamethrower::Campfire::RestApi

      def initialize(domain, token, server)
        @domain = domain
        @token = token
        @server = server
      end

      def rooms
        begin
          @rooms ||= Array.new.tap do |rooms|
            response = campfire_get("/rooms.json")
            json = JSON.parse(response.body)
            @server.log.debug json
            case response
            when Net::HTTPSuccess
              json['rooms'].each do |room|
                rooms << Room.new(@domain, @token, room)
              end
            end
          end
        rescue SocketError
          @server.send_message @server.reply(Flamethrower::Irc::Codes::RPL_MOTD, ":ERROR: Unable to fetch room list! Check your connection?")
          []
        end
      end

    end
  end
end
