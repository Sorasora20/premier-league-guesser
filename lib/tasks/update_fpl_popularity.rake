namespace :fpl do
  desc "FPL APIから人気度（知名度）を取得してPlayerデータを更新する"
  task update_popularity: :environment do
    puts "【ステップ4】FPL公式APIから人気度（selected_by_percent）を取得しています..."
    begin
      require 'json'
      require 'open-uri'
      
      fpl_url = 'https://fantasy.premierleague.com/api/bootstrap-static/'
      fpl_data = JSON.parse(URI.open(fpl_url).read)
      
      fpl_elements = fpl_data['elements']
      
      players = Player.all
      matched_count = 0
      
      def normalize_to_words(name)
        ActiveSupport::Inflector.transliterate(name.to_s).downcase.gsub(/[^a-z\s]/, '').split
      end

      def normalize_name(name)
        ActiveSupport::Inflector.transliterate(name.to_s).downcase.gsub(/[^a-z]/, '')
      end
      
      fpl_elements.each do |fpl_player|
        first_name = fpl_player['first_name']
        second_name = fpl_player['second_name']
        web_name = fpl_player['web_name']
        popularity = fpl_player['selected_by_percent'].to_f
        
        db_player = players.find do |p|
          db_words = normalize_to_words(p.name)
          normalized_p_name = normalize_name(p.name)
          
          fpl_words = normalize_to_words("#{first_name} #{second_name} #{web_name}")
          normalized_fpl_full = normalize_name("#{first_name} #{second_name}")
          normalized_web = normalize_name(web_name)

          basic_match = (
            normalized_p_name == normalized_fpl_full ||
            normalized_p_name.include?(normalized_fpl_full) ||
            normalized_fpl_full.include?(normalized_p_name) ||
            (normalized_p_name.include?(normalize_name(first_name)) && normalized_p_name.include?(normalize_name(second_name))) ||
            normalized_p_name == normalized_web
          )

          # DBのフルネームの「全単語」がFPLの名前のどこかに含まれているか
          word_match = db_words.all? { |w| fpl_words.any? { |fw| fw.include?(w) } || normalized_fpl_full.include?(w) }

          # Tsimikas / Mudryk 対策：頭文字が一致し、かつラストネーム（またはWebネーム）が一致するか
          db_first_name_initial = db_words.first[0] if db_words.length > 1
          db_last_name = db_words.last
          fpl_first_name_initial = normalize_name(first_name)[0]
          fpl_last_name = normalize_name(second_name)
          
          initial_match = (
            db_words.length > 1 &&
            fpl_first_name_initial &&
            db_first_name_initial == fpl_first_name_initial &&
            (db_last_name == fpl_last_name || db_last_name == normalized_web)
          )

          basic_match || word_match || initial_match
        end
        
        if db_player
          db_player.update!(popularity: popularity)
          matched_count += 1
        end
      end
      puts "FPLデータの照合完了！ #{players.count}人中 #{matched_count}人の人気度データを更新しました。"
    rescue => e
      puts "FPLデータの取得中にエラーが発生しました: #{e.message}"
    end
  end
end
