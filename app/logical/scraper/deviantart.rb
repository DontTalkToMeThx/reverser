# frozen_string_literal: true

module Scraper
  # https://www.deviantart.com/developers/http/v1/20210526
  # https://www.deviantart.com/developers/console
  class Deviantart < Base
    API_PREFIX = "https://www.deviantart.com/api/v1/oauth2"

    def init
      @next_offset = nil
    end

    def self.enabled?
      Config.deviantart_client_id.present? && Config.deviantart_client_secret.present?
    end

    def fetch_next_batch
      json = make_api_call("/gallery/all", {
        username: url_identifier,
        limit: 24,
        mature_content: true,
        offset: @next_offset,
      })
      end_reached unless json["has_more"]
      @next_offset = json["next_offset"]
      json["results"].reject { |r| r["content"].nil? }
    end

    def to_submission(submission)
      s = Submission.new
      # Extract number from https://www.deviantart.com/kenket/art/Rowdy-829623906
      s.identifier = submission["url"].match(/-([0-9]*)$/)[1]
      s.title = submission["title"]
      # FIXME: Title is only available when doing deviation/{deviationid}?expand=deviation.fulltext
      s.description = ""
      s.created_at = DateTime.strptime(submission["published_time"], "%s")
      s.add_file({}.tap do |hash|
        hash[:url_data] = [submission["deviationid"]] if submission["is_downloadable"]
        hash[:url] = submission["content"]["src"].gsub(/q_\d+(,strp)?/, "q_100") unless submission["is_downloadable"]
        hash[:created_at] = s.created_at
        hash[:identifier] = ""
      end)
      s
    end

    def get_download_link(data)
      make_api_call("/deviation/download/#{data[0]}")["src"]
    end

    def fetch_api_identifier
      json = make_api_call("/user/profile/#{url_identifier}")
      return nil if json["error_code"] == 2

      json.dig("user", "userid")
    end

    private

    def make_api_call(endpoint, query = {})
      fetch_json("#{API_PREFIX}#{endpoint}",
        query: {
          access_token: access_token,
          **query,
        },
        headers: {
          "dA-minor-version": "20210526",
        },
      )
    end

    def access_token
      Cache.fetch("deviantart-token", 55.minutes) do
        response = fetch_json("https://www.deviantart.com/oauth2/token", query: {
          grant_type: "client_credentials",
          client_id: Config.deviantart_client_id,
          client_secret: Config.deviantart_client_secret,
        })
        response["access_token"]
      end
    end
  end
end
