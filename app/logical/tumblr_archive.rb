# frozen_string_literal: true

# Archive Structure
#
# media
# -----| reblog_post_id1.jpg
# -----| reblog_post_id2_0.jpg
# -----| reblog_post_id2_1.jpg
# -----| reblog_post_id3.gif
# posts.zip
# -----| html
# ----------| reblog_post_id1.html
# ----------| reblog_post_id2.html
# ----------| reblog_post_id3.html
# -----| style.css
# -----| posts_index.html
class TumblrArchive
  URL_ID_REGEX = %r{tumblr\.com/post/(?<id>\d*)/}

  def initialize(path)
    @path = path
  end

  def import_submission_files
    Zip::File.open(@path) do |zip_file|
      posts_zip_entry = zip_file.glob("posts.zip").first

      Zip::File.open_buffer(posts_zip_entry.get_input_stream.read) do |posts_zip|
        # For each reblogged post
        posts_zip.glob("html/*").each do |reblog_entry|
          html = Nokogiri::HTML(reblog_entry.get_input_stream)
          original_post_url = html.at(".tumblr_blog")["href"]
          original_post_id = URL_ID_REGEX.match(original_post_url)[:id]
          submission = ArtistSubmission.joins(:artist_url).find_by(identifier_on_site: original_post_id, artist_url: { site_type: "tumblr" })
          next if submission.submission_files.any?

          reblog_post_id = File.basename(reblog_entry.name, ".html")
          media_files = zip_file.glob("media/#{reblog_post_id}*.*")
          media_files.each.with_index do |file, index|
            bin_file = Tempfile.new(binmode: true)
            bin_file.write(file.get_input_stream.read)
            bin_file.rewind
            SubmissionFile.from_bin_file(bin_file, artist_submission_id: submission.id,
                                                   url: "file:///#{file.name}",
                                                   created_at: submission.created_at_on_site,
                                                   file_identifier: index)
          end
        end
      end
    end
  end
end
