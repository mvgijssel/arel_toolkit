if Gem.loaded_specs.key?('postgres_ext')
  describe PostgresExt do
    ActiveRecord::Schema.define do
      self.verbose = false

      create_table :game_scores, force: true do |t|
        t.references :game
        t.references :user
        t.timestamps
      end

      create_table :game_games, force: true, &:timestamps

      create_table :game_users, force: true, &:timestamps
    end

    module Game
      class ApplicationModel < ActiveRecord::Base
        self.abstract_class = true
        self.table_name_prefix = 'game_'
      end

      class Score < ApplicationModel
        belongs_to :game
        belongs_to :user
      end

      class Game < ApplicationModel
      end

      class User < ApplicationModel
      end
    end

    class SomeMiddleware
      def self.call(arel, _context)
        arel
      end
    end

    it 'works for Game::Score.with CTE' do
      Arel.middleware.apply([SomeMiddleware]) do
        game = Game::Game.create!
        user = Game::User.create!
        score = Game::Score.create! game: game, user: user
        _other_score = Game::Score.create! game: Game::Game.create!, user: Game::User.create!
        query = Game::Score
          .with(my_games: Game::Game.where(id: game))
          .joins('INNER JOIN "my_games" ON "game_scores"."game_id" = "my_games"."id"')

        expect(SomeMiddleware).to receive(:call).and_wrap_original do |m, arel, context|
          expect(arel.to_sql).to eq context[:original_sql]

          m.call(arel, context)
        end

        expect(query.load).to eq [score]
      end
    end

    # TODO: broken in the gem
    xit 'works for Game::Score.from_cte CTE' do
      Arel.middleware.apply([SomeMiddleware]) do
        game = Game::Game.create!
        user = Game::User.create!
        score = Game::Score.create! game: game, user: user
        _other_score = Game::Score.create! game: Game::Game.create!, user: Game::User.create!
        query = Game::Score.from_cte('scores_for_game', Game::Score.where(game_id: game)).where(user_id: user)

        expect(SomeMiddleware).to receive(:call).and_wrap_original do |m, arel, context|
          expect(arel.to_sql).to eq context[:original_sql]

          m.call(arel, context)
        end

        expect(query.load).to eq [score]
      end
    end
  end
end
