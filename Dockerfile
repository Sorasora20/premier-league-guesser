FROM ruby:3.3-slim

RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev nodejs git pkg-config

# 作業ディレクトリの作成と設定
WORKDIR /app

# 依存関係のコピーとインストール
COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock
RUN bundle install

# プロジェクト全体のコピー
COPY . /app

# アセットのプリコンパイル (Production環境用)
RUN SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile

# entrypoint.sh のコピーと設定
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

# Railsサーバーの起動
EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]
