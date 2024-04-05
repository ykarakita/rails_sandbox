# frozen_string_literal: true

ActiveRecord::Base.logger = Logger.new($stdout)

puts "======== left_outer_joins ========="
# => 外部結合して主テーブルを絞り込んだりソートしたりしたいときに使う

users = User.left_outer_joins(:posts).order("posts.created_at")
users.each do |u|
  u.posts.pluck(:content)
end
puts users.size
# => 1000
# Userの数はPostの数になる
# User1 -> Post1
# User1 -> Post2
# User2 -> Post3

#   SELECT
#     "users" . *
#   FROM
#     "users" LEFT OUTER JOIN "posts"
#       ON "posts"."user_id" = "users"."id"
#   ORDER BY
#     posts.created_at
#
#   SELECT
#     "posts"."content"
#   FROM
#     "posts"
#   WHERE
#     "posts"."user_id" = $1  [["user_id", "fc4ec9aa-3bbc-4b5a-bf64-0b44b341458c"]]
#
#    以下 N+1

puts "======== eager_load ========="
# => 外部結合して主テーブルを絞り込んだりソートしたりしたい、かつ、結合した関連テーブルのデータも参照したい場合に使う

users = User.eager_load(:posts).order("posts.created_at")
users.each do |u|
  u.posts.pluck(:content)
end
puts users.size
# => 100
# Userの数はユニークになる
# User1 -> Post1, Post2
# User2 -> Post3

#   SELECT
#     "users"."id" AS t0_r0
#     ,"users"."first_name" AS t0_r1
#     ,"users"."last_name" AS t0_r2
#     ,"users"."email" AS t0_r3
#     ,"users"."age" AS t0_r4
#     ,"users"."created_at" AS t0_r5
#     ,"users"."updated_at" AS t0_r6
#     ,"posts"."id" AS t1_r0
#     ,"posts"."content" AS t1_r1
#     ,"posts"."user_id" AS t1_r2
#     ,"posts"."created_at" AS t1_r3
#     ,"posts"."updated_at" AS t1_r4
#   FROM
#     "users" LEFT OUTER JOIN "posts"
#       ON "posts"."user_id" = "users"."id"
#   ORDER BY
#     posts.created_at

puts "======== preload ========="
# => 関連テーブルのデータでソートや絞り込みをする必要がない場合に使う

users = User.preload(:posts)
users.each do |u|
  u.posts.pluck(:content)
end

# SELECT
#     "users" . *
#   FROM
#     "users"
#
# SELECT
#     "posts" . *
#   FROM
#     "posts"
#   WHERE
#     "posts"."user_id" IN (
#       $1
#       ,$2
#       ,$3
#       ,$4
#     )  [["user_id", "fb706f44-ae63-48dd-ad33-5ce44c2bef3e"], ["user_id", "e4a9f68e-fb09-48ed-9441-c7b487f24bb7"], ["user_id", "a8c6cda9-76ad-4cca-a8e2-4bcc2fdab879"], ["user_id", "bd084f0c-b3f1-408a-9579-d8606e9cbaf1"]]
