require 'date'
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  devise :omniauthable, omniauth_providers: [:facebook]
  has_many :answers
  has_many :facebook_likes, dependent: :destroy
  has_many :choices, through: :answers
  has_many :user_images, dependent: :destroy
  has_many :messages, dependent: :destroy
  belongs_to :community
  accepts_nested_attributes_for :user_images

  validates :first_name, presence: true
  validates :last_name, presence: true

  before_destroy :destroy_matches

  def name
    email
  end


  def matches
    likes + been_liked
  end

  def conversations
    full_matches.map do |match|
      match.conversation
    end
  end

  def unstarted_chats
    full_matches = self.full_matches
    unstarted_chats = []
    full_matches.each do |match|
      unstarted_chats << match if match.conversation.nil?
    end
    unstarted_chats
  end

  def started_chats
    full_matches = self.full_matches
    started_chats = []
    full_matches.each do |match|
      started_chats << match unless match.conversation.nil?
    end
    started_chats
  end

  def age
    unless birthday.nil?
      difference = (Date.today - birthday).to_i
      (difference/365.25).to_i
    end
  end

  def unstarted_users
    other_users = []
    unstarted_chats.each do |match|
      [match.first_user_id, match.second_user_id].each do |user|
        other_users << user if user != id
      end
    end
    other_users
  end

  def started_users
    other_users = []
    started_chats.each do |match|
      [match.first_user_id, match.second_user_id].each do |user|
        other_users << user if user != id
      end
    end
    other_users
  end

  def conversations_sorted_by_date
    convos = []
    started_chats.each do |match|
      convos << match.conversation
    end
    sorted_convos = convos.sort { |convo| convo }
    sorted_convos.reverse
  end

  def likes # return only when YOUVE BEEN THE FIRST to like
    Match.where(first_user: self)
  end

  def been_liked # second_user denotes the person who HAS BEEN LIKED by the PERSON WHO LIKED FIRST
    Match.where(second_user: self)
  end

  def full_matches
    Match.where(first_user: self).or(Match.where(second_user: self)).where(mutual: true)
  end

  def likes_user(target)
    Match.where(first_user: self, second_user: target)
  end

  def self.find_for_facebook_oauth(auth)
    user_params = auth.slice(:provider, :uid)
    user_params.merge! auth.info.slice(:email, :first_name, :last_name)
    user_params[:facebook_picture_url] = auth.info.image

    user_params[:gender] = auth.extra.raw_info.gender
    user_params[:friends] = auth.extra.raw_info.friends
    user_params[:birthday] = Date.strptime(auth.extra.raw_info.birthday, '%m/%d/%Y')


    user_params[:token] = auth.credentials.token
    user_params[:token_expiry] = Time.at(auth.credentials.expires_at)
    user_params = user_params.to_h

    user = User.find_by(provider: auth.provider, uid: auth.uid)
    user ||= User.find_by(email: auth.info.email) # User did a regular sign up in the past.
    if user
      user.update(user_params)
    else
      user = User.new(user_params)
      user.password = Devise.friendly_token[0,20]  # Fake password for validation

      # NEEDS CHANGING
      user.community = Community.first


      user.save
      # user.persist_fblikes(auth)
      user.persist_user_fb_photos
    end
    return user
  end

  # def persist_fblikes(auth)
  #   likes_hashie = auth.extra.raw_info.likes.data
  #   likes_hashie.each do |like|
  #     fb_like = FacebookLike.new(like_id: like.id, name: like.name)
  #     fb_like.user = self
  #     fb_like.save
  #   end
  # end

  def persist_user_fb_photos
    url_one = "https://graph.facebook.com/#{self.uid}/albums?access_token=#{self.token}"
    albums_hashes = JSON.parse(open(url_one).read)["data"]

    profile_pictures = [] # list of photos within the profile pictures album
    albums_hashes.each do |album|
      if album["name"] == "Profile Pictures"
        url_two = "https://graph.facebook.com/#{album["id"]}/photos?access_token=#{self.token}"
        profile_pictures << JSON.parse(open(url_two).read)["data"] # puts the photos of each album into photos array
      end
    end

    profile_pictures.flatten.first(6).each do |photo|
      fb_photo = UserImage.new(fb_photo_id: photo["id"]) # unique id from facebook for the photo
      fb_photo.user = self
      fb_photo.save
    end
  end

  def all_fb_photos_page
    url = "https://graph.facebook.com/#{self.uid}/photos?fields=picture&access_token=#{self.token}"
    photos_array = JSON.parse(open(url).read)["data"]
    tagged_photos = []
    photos_array.each do |photo|
      tagged_photos << {url: photo["picture"], fb_photo_id: photo["id"]}
    end
    tagged_photos
  end


  def destroy_matches
    matches.each &:destroy
  end

end
