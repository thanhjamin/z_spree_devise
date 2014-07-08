module Spree
  class User < ActiveRecord::Base
    include Core::UserAddress
    if Spree.version > '2.2.0' && defined?(Core::UserPaymentSource)
      include Core::UserPaymentSource
    end

    devise :database_authenticatable, :registerable, :recoverable,
           :rememberable, :trackable, :validatable, :encryptable, :encryptor => 'authlogic_sha512'

    has_many :orders
    has_attached_file :photo,
                      styles: { mini: '48x48>', small: '100x100>', product: '240x240>', large: '600x600>' },
                      url: '/spree/medical_recommendation/:id/:style/:basename.:extension',
                      path: ':rails_root/public/spree/medical_recommendation/:id/:style/:basename.:extension',
                      convert_options: { all: '-strip -auto-orient -colorspace sRGB' }

    before_validation :set_login
    before_destroy :check_completed_orders

    users_table_name = User.table_name
    roles_table_name = Role.table_name

    scope :admin, -> { includes(:spree_roles).where("#{roles_table_name}.name" => "admin") }

    class DestroyWithOrdersError < StandardError; end

    def self.admin_created?
      User.admin.count > 0
    end

    def admin?
      has_spree_role?('admin')
    end

    protected
      def password_required?
        !persisted? || password.present? || password_confirmation.present?
      end

    private

      def check_completed_orders
        raise DestroyWithOrdersError if orders.complete.present?
      end

      def set_login
        # for now force login to be same as email, eventually we will make this configurable, etc.
        self.login ||= self.email if self.email
      end
  end
end
