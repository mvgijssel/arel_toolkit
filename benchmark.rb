GC.disable

require 'arel'
require 'active_record'
require 'memory_profiler'
require 'json'
require 'stackprof'

require './lib/arel/enhance'
require './lib/arel/extensions'
require './lib/arel/sql_to_arel'

ActiveRecord::Base.establish_connection(
  adapter: 'postgresql',
  host: 'localhost',
  databse: 'arel_toolkit_test',
  username: 'postgres',
)

# rubocop:disable Layout/LineLength
SQL = %{
SELECT COUNT("hacktivity_items"."id") FROM (SELECT "hacktivity_items".* FROM (SELECT "hacktivity_items".* FROM (SELECT "hacktivity_items".*, (NULLIF(current_setting('secure.requester_id'), ''))::integer AS "_requester_id" FROM (SELECT "outer_hacktivity_items".*, EXISTS (SELECT 1 FROM "public"."reports" INNER JOIN "public"."teams" ON "teams"."id" = "reports"."team_id" WHERE "teams"."state" = 5 AND "reports"."disclosed_at" IS NOT NULL AND "reports"."public_view" = 'full' AND "reports"."id" = "outer_hacktivity_items"."report_id") AS "is_someone_visiting_a_public_report", EXISTS (SELECT 1 FROM "public"."reports" INNER JOIN "public"."teams" ON "teams"."id" = "reports"."team_id" INNER JOIN "public"."whitelisted_reporters" ON "whitelisted_reporters"."team_id" = "teams"."id" WHERE "teams" ."state" = 4 AND "teams"."allows_private_disclosure" = 't'::bool AND (("whitelisted_reporters"."user_id" IS NULL AND NULLIF(current_setting('secure.requester_id'), '') IS NULL) OR "whitelisted_reporters"."user_id" = (NULLIF(current_setting('secure.requester_id'), ''))::integer) AND "reports"."disclosed_at" IS NOT NULL AND "reports"."public_view" = 'full' AND "reports"."id" = "outer_hacktivity_items"."report_id") AS "is_someone_visiting_a_report_privately_disclosed_to_them", EXISTS (SELECT 1 FROM "public"."reports" WHERE "reports"."hacker_published" = 't'::bool AND "reports"."disclosed_at" IS NOT NULL AND "reports"."id" = "outer_hacktivity_items"."report_id") AS "is_hacker_published", EXISTS (SELECT 1 FROM "public"."teams" INNER JOIN "public"."team_members" ON "team_members"."team_id" = "teams"."id" WHERE (("team_members"."user_id" IS NULL AND NULLIF(current_setting('secure.requester_id'), '') IS NULL) OR "team_members"."user_id" = (NULLIF(current_setting('secure.requester_id'), ''))::integer) AND "team_members"."user_id" IS NOT NULL AND "teams"."id" = "outer_hacktivity_items"."team_id") AS "is_team_team_member", EXISTS (SELECT 1 FROM "public"."teams" WHERE "teams"."state" = 5 AND "teams"."id" = "outer_hacktivity_items"."team_id") AS "is_team_public", EXISTS (SELECT 1 FROM "public"."teams" INNER JOIN "public"."whitelisted_reporters" ON "whitelisted_reporters"."team_id" = "teams"."id" INNER JOIN "public"."users" ON "users"."id" = "whitelisted_reporters"."user_id" WHERE (("users"."id" IS NULL AND NULLIF(current_setting('secure.requester_id'), '') IS NULL) OR "users"."id" = (NULLIF(current_setting('secure.requester_id'), ''))::integer) AND "users"."id" IS NOT NULL AND "teams"."id" = "outer_hacktivity_items"."team_id") AS "is_team_whitelisted_reporter", EXISTS (SELECT 1 FROM "public"."teams" WHERE "teams"."state" = 4 AND "teams"."id" = "outer_hacktivity_items"."team_id") AS "is_team_private", EXISTS (SELECT 1 FROM "public"."teams" WHERE "teams"."offers_bounties" = 't'::bool AND "teams"."hide_bounty_amounts" = 'f'::bool AND "teams"."id" = "outer_hacktivity_items"."team_id") AS "is_team_shows_bounty_amounts" FROM "public"."hacktivity_items" "outer_hacktivity_items") AS "hacktivity_items" WHERE "hacktivity_items"."is_team_public" = 't'::bool OR ("hacktivity_items"."is_team_private" = 't'::bool AND ("hacktivity_items"."is_team_team_member" = 't'::bool OR "hacktivity_items"."is_team_whitelisted_reporter" = 't'::bool)) OR "hacktivity_items"."is_hacker_published" = 't'::bool) hacktivity_items) AS "hacktivity_items" LEFT OUTER JOIN (SELECT "reports".*, "new_j0"."disclosed_at" AS "__new_filterable_disclosed_at" FROM (SELECT "reports".*, (NULLIF(current_setting('secure.requester_id'), ''))::integer AS "_requester_id" FROM (SELECT "outer_reports".*, EXISTS (SELECT 1 FROM "public"."teams" INNER JOIN "public"."team_members" ON "team_members"."team_id" = "teams"."id" INNER JOIN "public"."users" ON "users"."id" = "team_members"."user_id" WHERE (("users"."id" IS NULL AND NULLIF(current_setting('secure.requester_id'), '') IS NULL) OR "users"."id" = (NULLIF(current_setting('secure.requester_id'), ''))::integer) AND "users"."id" IS NOT NULL AND "teams"."id" = "outer_reports"."team_id") AS "is_team_member", (("outer_reports"."reporter_id" IS NULL AND NULLIF(current_setting('secure.requester_id'), '') IS NULL) OR "outer_reports"."reporter_id" = (NULLIF(current_setting('secure.requester_id'), ''))::integer) AND "outer_reports"."reporter_id" IS NOT NULL AS "is_reporter", EXISTS (SELECT 1 FROM "public"."reports_users" INNER JOIN "public"."users" ON "users"."id" = "reports_users"."user_id" WHERE (("reports_users"."user_id" IS NULL AND NULLIF(current_setting('secure.requester_id'), '') IS NULL) OR "reports_users"."user_id" = (NULLIF(current_setting('secure.requester_id'), ''))::integer) AND "reports_users"."user_id" IS NOT NULL AND "reports_users"."report_id" = "outer_reports"."id") AS "is_external_user", EXISTS (SELECT 1 FROM "public"."report_retests" INNER JOIN "public"."report_retest_users" ON "report_retest_users"."report_retest_id" = "report_retests"."id" WHERE (EXISTS (SELECT "invitations".* FROM "public"."invitations" WHERE ("accepted_at" IS NOT NULL OR "expires_at" >= now() OR "expires_at" IS NULL) AND "invitations"."cancelled_at" IS NULL AND "invitations"."rejected_at" IS NULL AND "invitations"."id" = "report_retest_users"."invitation_id") OR (NOT (EXISTS (SELECT "invitations".* FROM "public"."invitations" WHERE "invitations"."id" = "report_retest_users"."invitation_id")))) AND (("report_retest_users"."user_id" IS NULL AND NULLIF(current_setting('secure.requester_id'), '') IS NULL) OR "report_retest_users"."user_id" = (NULLIF(current_setting('secure.requester_id'), ''))::integer) AND "report_retest_users"."user_id" IS NOT NULL AND "report_retests"."report_id" = "outer_reports"."id") AS "is_retester", EXISTS (SELECT 1 FROM "public"."teams" LEFT OUTER JOIN "public"."users" ON "users"."anc_triager" WHERE "outer_reports"."pre_submission_review_state" IS NOT NULL AND "teams"."state" IN (4, 5) AND "teams"."anc_enabled" = 't'::bool AND (("users"."id" IS NULL AND NULLIF(current_setting('secure.requester_id'), '') IS NULL) OR "users"."id" = (NULLIF(current_setting('secure.requester_id'), ''))::integer) AND "users"."id" IS NOT NULL AND "teams"."id" = "outer_reports"."team_id") AS "is_anc_triager", EXISTS (SELECT 1 FROM "public"."teams" INNER JOIN "public"."team_members" ON "team_members"."team_id" = "teams"."id" INNER JOIN "public"."users" ON "users"."id" = "team_members"."user_id" WHERE (("users"."id" IS NULL AND NULLIF(current_setting('secure.requester_id'), '') IS NULL) OR "users"."id" = (NULLIF(current_setting('secure.requester_id'), ''))::integer) AND "users"."hackerone_triager" = 't'::bool AND "users"."id" IS NOT NULL AND "teams"."id" = "outer_reports"."team_id") AS "is_hackerone_triager", EXISTS (SELECT 1 FROM "public"."report_collaborators" WHERE (("report_collaborators"."user_id" IS NULL AND NULLIF(current_setting('secure.requester_id'), '') IS NULL) OR "report_collaborators"."user_id" = (NULLIF(current_setting('secure.requester_id'), ''))::integer) AND "report_collaborators"."user_id" IS NOT NULL AND "report_collaborators"."report_id" = "outer_reports"."id") AS "is_report_collaborator", EXISTS (SELECT 1 FROM "public"."teams" WHERE "teams"."state" = 5 AND "outer_reports"."disclosed_at" IS NOT NULL AND "outer_reports"."public_view" = 'full' AND "teams"."id" = "outer_reports"."team_id") AS "is_someone_visiting_a_public_report", EXISTS (SELECT 1 FROM "public"."teams" WHERE "teams"."state" = 5 AND "outer_reports"."disclosed_at" IS NOT NULL AND "outer_reports"."public_view" = 'no-content' AND "teams"."id" = "outer_reports"."team_id") AS "is_someone_visiting_a_public_limited_report", EXISTS (SELECT 1 FROM "public"."teams" INNER JOIN "public"."whitelisted_reporters" ON "whitelisted_reporters"."team_id" = "teams"."id" WHERE "teams"."state" = 4 AND "teams"."allows_private_disclosure" = 't'::bool AND (("whitelisted_reporters"."user_id" IS NULL AND NULLIF(current_setting('secure.requester_id'), '') IS NULL) OR "whitelisted_reporters"."user_id" = (NULLIF(current_setting('secure.requester_id'), ''))::integer) AND "outer_reports"."disclosed_at" IS NOT NULL AND "outer_reports"."public_view" = 'full' AND "teams"."id" = "outer_reports"."team_id") AS "is_someone_visiting_a_report_privately_disclosed_to_them", "outer_reports"."hacker_published" = 't'::bool AND "outer_reports"."disclosed_at" IS NOT NULL AS "is_hacker_published" FROM "public"."reports" "outer_reports") AS "reports" WHERE "reports"."is_reporter" = 't'::bool OR "reports"."is_team_member" = 't'::bool OR "reports"."is_external_user" = 't'::bool OR "reports"."is_anc_triager" = 't'::bool OR "reports"."is_report_collaborator" = 't'::bool OR "reports"."is_someone_visiting_a_public_report" = 't'::bool OR "reports"."is_someone_visiting_a_public_limited_report" = 't'::bool OR "reports"."is_someone_visiting_a_report_privately_disclosed_to_them" = 't'::bool OR "reports"."is_hacker_published" = 't'::bool OR "reports"."is_retester" = 't'::bool) reports LEFT OUTER JOIN "public"."reports" "new_j0" ON "reports"."id" = "new_j0"."id" AND ("reports"."is_reporter" = 't'::bool OR "reports"."is_team_member" = 't'::bool OR "reports"."is_external_user" = 't'::bool OR "reports"."is_anc_triager" = 't'::bool OR "reports"."is_report_collaborator" = 't'::bool OR "reports"."is_someone_visiting_a_public_report" = 't'::bool OR "reports"."is_someone_visiting_a_public_limited_report" = 't'::bool OR "reports"."is_someone_visiting_a_report_privately_disclosed_to_them" = 't'::bool OR "reports"."is_hacker_published" = 't'::bool)) AS "reports" ON "reports"."id" = "hacktivity_items"."report_id" WHERE "reports"."__new_filterable_disclosed_at" IS NOT NULL) AS "hacktivity_items" LEFT OUTER JOIN "hacktivity_scores" ON "hacktivity_scores"."hacktivity_item_id" = "hacktivity_items"."id"
}.freeze
# rubocop:enable Layout/LineLength

def do_it
  arel = Arel.sql_to_arel SQL
  enhanced_arel = Arel.enhance(arel)

  enhanced_arel.query(class: Arel::Attributes::Attribute).each do |node|
    node.replace node
  end

  enhanced_arel
end

# Warm up
do_it

profile = StackProf.run(mode: :wall, raw: true) { do_it }
File.write('stackprof.json', JSON.generate(profile))

report = MemoryProfiler.report { do_it }
puts report.pretty_print

n = 100

Benchmark.bm do |benchmark|
  benchmark.report do
    n.times do
      do_it
    end
  end
end
