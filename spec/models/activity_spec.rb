require 'spec_helper'

describe Activity do
  let!(:user) { User.make }
  let!(:collection) { user.create_collection Collection.make_unsaved }

  it "creates one when collection is created" do
    assert_activity 'collection', 'created',
      'collection_id' => collection.id,
      'user_id' => user.id,
      'data' => {'name' => collection.name},
      'description' => "Collection '#{collection.name}' was created"
  end

  it "creates one when layer is created" do
    Activity.delete_all

    layer = collection.layers.make user: user, fields_attributes: [{kind: 'text', code: 'foo', name: 'Foo', ord: 1}]

    assert_activity 'layer', 'created',
      'collection_id' => collection.id,
      'layer_id' => layer.id,
      'user_id' => user.id,
      'data' => {'name' => layer.name, 'fields' => [{'id' => layer.fields.first.id, 'kind' => 'text', 'code' => 'foo', 'name' => 'Foo'}]},
      'description' => "Layer '#{layer.name}' was created with fields: Foo (foo)"
  end

  context "layer changed" do
    it "creates one when layer's name changes" do
      layer = collection.layers.make user: user, name: 'Layer1', fields_attributes: [{kind: 'text', code: 'foo', name: 'Foo', ord: 1}]

      Activity.delete_all

      layer.name = 'Layer2'
      layer.save!

      assert_activity 'layer', 'changed',
        'collection_id' => collection.id,
        'layer_id' => layer.id,
        'user_id' => user.id,
        'data' => {'name' => 'Layer1', 'changes' => {'name' => ['Layer1', 'Layer2']}},
        'description' => "Layer 'Layer1' was renamed to '#{layer.name}'"
    end

    it "creates one when layer's field is added" do
      layer = collection.layers.make user: user, name: 'Layer1', fields_attributes: [{kind: 'text', code: 'one', name: 'One', ord: 1}]

      Activity.delete_all

      layer.update_attributes! fields_attributes: [{kind: 'text', code: 'two', name: 'Two', ord: 2}]

      field = layer.fields.last

      assert_activity 'layer', 'changed',
        'collection_id' => collection.id,
        'layer_id' => layer.id,
        'user_id' => user.id,
        'data' => {'name' => 'Layer1', 'changes' => {'added' => [{'id' => field.id, 'code' => field.code, 'name' => field.name, 'kind' => field.kind}]}},
        'description' => "Layer 'Layer1' changed: text field 'Two' (two) was added"
    end

    it "creates one when layer's field's code changes" do
      layer = collection.layers.make user: user, name: 'Layer1', fields_attributes: [{kind: 'text', code: 'one', name: 'One', ord: 1}]

      Activity.delete_all

      field = layer.fields.last

      layer.update_attributes! fields_attributes: [{id: field.id, code: 'one1', name: 'One', ord: 1}]

      assert_activity 'layer', 'changed',
        'collection_id' => collection.id,
        'layer_id' => layer.id,
        'user_id' => user.id,
        'data' => {'name' => 'Layer1', 'changes' => {'changed' => [{'id' => field.id, 'code' => ['one', 'one1'], 'name' => 'One', 'kind' => 'text'}]}},
        'description' => "Layer 'Layer1' changed: text field 'One' (one) code changed to 'one1'"
    end

    it "creates one when layer's field's name changes" do
      layer = collection.layers.make user: user, name: 'Layer1', fields_attributes: [{kind: 'text', code: 'one', name: 'One', ord: 1}]

      Activity.delete_all

      field = layer.fields.last

      layer.update_attributes! fields_attributes: [{id: field.id, code: 'one', name: 'One1', ord: 1}]

      assert_activity 'layer', 'changed',
        'collection_id' => collection.id,
        'layer_id' => layer.id,
        'user_id' => user.id,
        'data' => {'name' => 'Layer1', 'changes' => {'changed' => [{'id' => field.id, 'code' => 'one', 'name' => ['One', 'One1'], 'kind' => 'text'}]}},
        'description' => "Layer 'Layer1' changed: text field 'One' (one) name changed to 'One1'"
    end

    it "creates one when layer's field's options changes" do
      layer = collection.layers.make user: user, name: 'Layer1', fields_attributes: [{kind: 'select_one', code: 'one', name: 'One', config: {'options' => [{'code' => '1', 'label' => 'One'}]}, ord: 1}]

      Activity.delete_all

      field = layer.fields.last

      begin
        layer.update_attributes! fields_attributes: [{id: field.id, code: 'one', name: 'One', kind: 'select_one', config: {'options' => [{'code' => '2', 'label' => 'Two'}]}, ord: 1}]
      rescue Exception => ex
        puts ex.backtrace
      end

      assert_activity 'layer', 'changed',
        'collection_id' => collection.id,
        'layer_id' => layer.id,
        'user_id' => user.id,
        'data' => {'name' => 'Layer1', 'changes' => {'changed' => [{'id' => field.id, 'code' => 'one', 'name' => 'One', 'kind' => 'select_one', 'config' => [{'options' => [{'code' => '1', 'label' => 'One'}]}, {'options' => [{'code' => '2', 'label' => 'Two'}]}]}]}},
        'description' => %(Layer 'Layer1' changed: select_one field 'One' (one) options changed from ["One (1)"] to ["Two (2)"])
    end

    it "creates one when layer's field is removed" do
      layer = collection.layers.make user: user, name: 'Layer1', fields_attributes: [{kind: 'text', code: 'one', name: 'One', ord: 1}, {kind: 'text', code: 'two', name: 'Two', ord: 2}]

      Activity.delete_all

      field = layer.fields.last

      layer.update_attributes! fields_attributes: [{id: field.id, _destroy: true}]

      assert_activity 'layer', 'changed',
        'collection_id' => collection.id,
        'layer_id' => layer.id,
        'user_id' => user.id,
        'data' => {'name' => 'Layer1', 'changes' => {'deleted' => [{'id' => field.id, 'code' => 'two', 'name' => 'Two', 'kind' => 'text'}]}},
        'description' => "Layer 'Layer1' changed: text field 'Two' (two) was deleted"
    end
  end

  it "creates one when layer is destroyed" do
    layer = collection.layers.make user: user, fields_attributes: [{kind: 'text', code: 'foo', name: 'Foo', ord: 1}]

    Activity.delete_all

    layer.destroy

    assert_activity 'layer', 'deleted',
      'collection_id' => collection.id,
      'layer_id' => layer.id,
      'user_id' => user.id,
      'data' => {'name' => layer.name},
      'description' => "Layer '#{layer.name}' was deleted"
  end

  it "creates one after creating a site" do
    layer = collection.layers.make user: user, fields_attributes: [{kind: 'text', code: 'beds', name: 'Beds', ord: 1}]
    field = layer.fields.first

    Activity.delete_all

    site = collection.sites.create! name: 'Foo', lat: 10.0, lng: 20.0, properties: {field.es_code => 20}, user: user

    assert_activity 'site', 'created',
      'collection_id' => collection.id,
      'user_id' => user.id,
      'site_id' => site.id,
      'data' => {'name' => site.name, 'lat' => site.lat, 'lng' => site.lng, 'properties' => site.properties},
      'description' => "Site '#{site.name}' was created"
  end

  it "creates one after importing a csv" do
    Activity.delete_all

    collection.import_csv user, %(
      resmap-id, name, lat, lng
      1, Site 1, 30, 40
    ).strip

    assert_activity 'collection', 'csv_imported',
      'collection_id' => collection.id,
      'user_id' => user.id,
      'data' => {'sites' => 1},
      'description' => "Import CSV: 1 site were imported"
  end

  context "site changed" do
    let!(:layer) { collection.layers.make user: user, fields_attributes: [{kind: 'numeric', code: 'beds', name: 'Beds', ord: 1}, {kind: 'numeric', code: 'tables', name: 'Tables', ord: 2}, {kind: 'text', code: 'text', name: 'Text', ord: 3}] }
    let(:beds) { layer.fields.first }
    let(:tables) { layer.fields.second }
    let(:text) { layer.fields.third }

    it "creates one after changing one site's name" do
      site = collection.sites.create! name: 'Foo', lat: 10.0, lng: 20.0, properties: {beds.es_code => 20}, user: user

      Activity.delete_all

      site.name = 'Bar'
      site.save!

      assert_activity 'site', 'changed',
        'collection_id' => collection.id,
        'user_id' => user.id,
        'site_id' => site.id,
        'data' => {'name' => 'Foo', 'changes' => {'name' => ['Foo', 'Bar']}},
        'description' => "Site 'Foo' was renamed to 'Bar'"
    end

    it "creates one after changing one site's location" do
      site = collection.sites.create! name: 'Foo', lat: 10.0, lng: 20.0, properties: {beds.es_code => 20}, user: user

      Activity.delete_all

      site.lat = 15.1234567
      site.save!

      assert_activity 'site', 'changed',
        'collection_id' => collection.id,
        'user_id' => user.id,
        'site_id' => site.id,
        'data' => {'name' => site.name, 'changes' => {'lat' => [10.0, 15.1234567], 'lng' => [20.0, 20.0]}},
        'description' => "Site '#{site.name}' changed: location changed from (10.0, 20.0) to (15.123457, 20.0)"
    end

    it "creates one after adding location in site without location" do
      site = collection.sites.create! name: 'Foo', properties: {beds.es_code => 20}, user: user

      Activity.delete_all

      site.lat = 15.1234567
      site.lng = 34.123456

      site.save!

      assert_activity 'site', 'changed',
        'collection_id' => collection.id,
        'user_id' => user.id,
        'site_id' => site.id,
        'data' => {'name' => site.name, 'changes' => {'lat' => [ nil, 15.1234567], 'lng' => [nil, 34.123456]}},
        'description' => "Site '#{site.name}' changed: location changed from (nothing) to (15.123457, 34.123456)"
    end

    it "creates one after removing location in site with location" do
      site = collection.sites.create! name: 'Foo', lat: 10.0, lng: 20.0, properties: {beds.es_code => 20}, user: user

      Activity.delete_all

      site.lat = nil
      site.lng = nil

      site.save!

      assert_activity 'site', 'changed',
        'collection_id' => collection.id,
        'user_id' => user.id,
        'site_id' => site.id,
        'data' => {'name' => site.name, 'changes' => {'lat' => [10.0, nil], 'lng' => [20.0, nil]}},
        'description' => "Site '#{site.name}' changed: location changed from (10.0, 20.0) to (nothing)"
    end

    it "creates one after adding one site's property" do
      site = collection.sites.create! name: 'Foo', lat: 10.0, lng: 20.0, properties: {}, user: user

      Activity.delete_all

      site.properties_will_change!
      site.properties[beds.es_code] = 30
      site.save!

      assert_activity 'site', 'changed',
        'collection_id' => collection.id,
        'user_id' => user.id,
        'site_id' => site.id,
        'data' => {'name' => site.name, 'changes' => {'properties' => [{}, {beds.es_code => 30}]}},
        'description' => "Site '#{site.name}' changed: 'beds' changed from (nothing) to 30"
    end

    it "creates one after changing one site's property" do
      site = collection.sites.create! name: 'Foo', lat: 10.0, lng: 20.0, properties: {beds.es_code => 20}, user: user

      Activity.delete_all

      site.properties_will_change!
      site.properties[beds.es_code] = 30
      site.save!

      assert_activity 'site', 'changed',
        'collection_id' => collection.id,
        'user_id' => user.id,
        'site_id' => site.id,
        'data' => {'name' => site.name, 'changes' => {'properties' => [{beds.es_code => 20}, {beds.es_code => 30}]}},
        'description' => "Site '#{site.name}' changed: 'beds' changed from 20 to 30"
    end

    it "creates one after changing many site's properties" do
      site = collection.sites.create! name: 'Foo', lat: 10.0, lng: 20.0, properties: {beds.es_code => 20, text.es_code => 'foo'}, user: user

      Activity.delete_all

      site.properties_will_change!
      site.properties[beds.es_code] = 30
      site.properties[text.es_code] = 'bar'
      site.save!

      assert_activity 'site', 'changed',
        'collection_id' => collection.id,
        'user_id' => user.id,
        'site_id' => site.id,
        'data' => {'name' => site.name, 'changes' => {'properties' => [{beds.es_code => 20, text.es_code => 'foo'}, {beds.es_code => 30, text.es_code => 'bar'}]}},
        'description' => "Site '#{site.name}' changed: 'beds' changed from 20 to 30, 'text' changed from 'foo' to 'bar'"
    end

    it "doesn't create one after siglaning properties will change but they didn't change" do
      site = collection.sites.create! name: 'Foo', lat: 10.0, lng: 20.0, properties: {beds.es_code => 20}, user: user

      Activity.delete_all

      site.properties_will_change!
      site.save!

      Activity.count.should eq(0)
    end

    it "doesn't create one if lat/lng updated but not changed" do
      site = collection.sites.create! name: 'Foo', lat: "-1.9537", lng: "30.10309", properties: {beds.es_code => 20}, user: user

      Activity.delete_all

      site.lat = "-1.9537"
      site.lng = "30.103090000000066"
      site.save!

      Activity.count.should eq(0)
    end
  end

  it "creates one after destroying a site" do
    site = collection.sites.create! name: 'Foo', lat: 10.0, lng: 20.0, location_mode: :manual, user: user

    Activity.delete_all

    site.destroy

    assert_activity 'site', 'deleted',
      'collection_id' => collection.id,
      'user_id' => user.id,
      'site_id' => site.id,
      'data' => {'name' => site.name},
      'description' => "Site '#{site.name}' was deleted"
  end

  let(:user2) { collection.users.make email: 'user2@email.com'}
  it "creates one after creating a membership but not the first one" do
    Activity.delete_all
    membership = collection.memberships.create! user_id: user2.id
    assert_activity 'membership', 'created',
      'collection_id' => collection.id,
      'user_id' => user2.id,
      'data' => {},
      'description' => "Membership was created"
  end

  it "creates one after destroying a membership" do
    membership = collection.memberships.create! user_id: user2.id
    Activity.delete_all
    membership.destroy
    assert_activity 'membership', 'deleted',
      'collection_id' => collection.id,
      'user_id' => user2.id,
      'data' => {},
      'description' => "Membership was deleted"
  end

  it "creates one after creating a layer_membership" do
    membership = collection.memberships.create! user_id: user2.id
    layer = collection.layers.make user: user, fields_attributes: [{kind: 'text', code: 'foo', name: 'Foo', ord: 1}]
    Activity.delete_all
    layer_membership = LayerMembership.create! :layer_id => layer.id, :membership => membership, :read => true, :write => false
    assert_activity 'layer_membership', 'created',
      'collection_id' => collection.id,
      'user_id' => user2.id,
      'layer_id' => layer.id,
      'description' => "Read permission created for layer '#{layer.name}'"
  end

  it "creates one after destroying a layer_membership" do
    membership = collection.memberships.create! user_id: user2.id
    layer = collection.layers.make user: user, fields_attributes: [{kind: 'text', code: 'foo', name: 'Foo', ord: 1}]
    layer_membership = LayerMembership.create! :layer_id => layer.id, :membership => membership, :read => true, :write => false
    Activity.delete_all
    layer_membership.destroy
    assert_activity 'layer_membership', 'deleted',
      'collection_id' => collection.id,
      'user_id' => user2.id,
      'layer_id' => layer.id,
      'description' => "Permission was deleted in layer '#{layer.name}'"
  end

  it "creates one after changing a layer_membership by setting layer access" do
    membership = collection.memberships.create! user_id: user2.id
    layer = collection.layers.make user: user, fields_attributes: [{kind: 'text', code: 'foo', name: 'Foo', ord: 1}]
    layer_membership = LayerMembership.create! :layer_id => layer.id, :membership => membership, :read => true, :write => false
    Activity.delete_all
    params = {:layer_id => layer.id, :verb => :write, :access => true}
    membership.set_layer_access params

    assert_activity 'layer_membership', 'changed',
      'collection_id' => collection.id,
      'user_id' => user2.id,
      'layer_id' => layer.id,
      'description' => "Permission changed from read to write in layer '#{layer.name}'"
  end

  it "creates one after changing name permission" do
    Activity.delete_all
    membership = collection.memberships.first
    params = {:object => 'name', :new_action => 'update'}
    membership.set_access params

    assert_activity 'name_permission', 'changed',
      'collection_id' => collection.id,
      'user_id' => user.id,
      'description' => "Name permission changed from read to update"
  end

  it "creates one after changing location permission" do
    Activity.delete_all
    membership = collection.memberships.first
    params = {:object => 'location', :new_action => 'update'}
    membership.set_access params

    assert_activity 'location_permission', 'changed',
      'collection_id' => collection.id,
      'user_id' => user.id,
      'description' => "Location permission changed from read to update"
  end

  def assert_activity(item_type, action, options = {})
    activities = Activity.all
    if (item_type == 'collection' && action == 'created')
      activities.length.should eq(2)
    else
      activities.length.should eq(1)
    end
    activities[0].item_type.should eq(item_type)
    activities[0].action.should eq(action)
    options.each do |key, value|
      activities[0].send(key).should eq(value)
    end
  end
end
