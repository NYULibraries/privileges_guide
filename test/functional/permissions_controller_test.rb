require 'test_helper'

class PermissionsControllerTest < ActionController::TestCase

  def setup
    @request.env["devise.mapping"] = Devise.mappings[:user]
    sign_in users(:admin)
  end

  test "should get index" do
   get :index

   assert_not_nil assigns(:permissions)
   assert_response :success
   assert_template :index
  end

  test "should get new" do
    get :new
    assert_not_nil assigns(:permission)
    assert_response :success
    assert_template :new
  end

  test "should create permission" do
    assert_difference('Permission.count') do
      post :create, params: { permission: {code: "uniquecode1234", from_aleph: true} }
    end

    assert_response :redirect
    assert_redirected_to permission_path(assigns(:permission))
  end

  test "should NOT create permission" do
    assert_no_difference('Permission.count') do
      post :create, params: { permission: {code: nil, from_aleph: true} }
    end

    assert assigns(:permission)
    assert_no_match(/^nyu_ag_noaleph_/, assigns(:permission).code)
    assert_template :new
  end

  test "should show permission" do
    get :show, params: { id: Permission.first.id }
    assert_not_nil assigns(:permission)
    assert_response :success
    assert_template :show
  end

  test "should get edit" do
    get :edit, params: { id: Permission.first.id }
    assert_response :success
  end

  test "should update permission" do
    put :update, params: { id: Permission.first.id, permission: {code: "uniquecode1234"} }

    assert assigns(:permission)
    assert_redirected_to permission_path(assigns(:permission))
  end

  test "should NOT update permission" do
    put :update, params: { id: Permission.first.id, permission: {code: nil } }

    assert assigns(:permission)
    assert_not_nil flash[:danger]
    assert_template :edit
  end

  test "should destroy permission" do
    assert_difference('Permission.count', -1) do
      delete :destroy, params: { id: Permission.first.id }
    end

    assert_redirected_to permissions_path
  end

  test "should update order" do
    post :update_order, params: { permissions: [permissions(:aleph_two).id, permissions(:aleph_one).id] }

    assert_equal permissions(:aleph_two).id, Permission.by_sort_order.first.id
    assert_equal permissions(:aleph_one).id, Permission.by_sort_order.offset(1).limit(1).first.id
    assert_redirected_to permissions_url
  end

end
