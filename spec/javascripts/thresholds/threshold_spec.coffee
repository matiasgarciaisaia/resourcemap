describe 'Threshold', ->
  beforeEach ->
    window.runOnCallbacks 'thresholds'

    @collectionId = 1
    window.model = new MainViewModel @collectionId
    @field_beds = new Field id: '1', code: 'beds'
    window.model.fields [@field_beds]
    @threshold = new Threshold { id: 1, collection_id: @collectionId, ord: 1, color: '#ff0000', property_name: "bed", sites: "siemreap hc", is_all_site: true, is_all_condition: true, is_notify: true, message_notification: "alert_01", conditions: [{ field: '1', op: 'lt', type: 'value', value: 10, compare_field: '1' }] }

  it 'should have 1 condition', ->
    expect(@threshold.conditions().length).toEqual 1

  it 'should be valid', ->
    expect(@threshold.valid()).toBeTruthy()

  it 'should not be valid when have invalid condition', ->
    @threshold.conditions()[0].value null
    expect(@threshold.valid()).toBeFalsy()

  it 'should convert to json', ->
    expect(@threshold.toJSON()).toEqual {
      ord: 1
      color: '#ff0000'
      phone_notification : [ ]
      email_notification : [ ]
      message_notification : 'alert_01'
      is_notify: 'true'
      property_name: "bed"
      is_all_site: 'true'
      is_all_condition: 'true'
      sites : []
      conditions: [{field: '1', op: 'lt', value: 10, type: 'value', compare_field: '1'}]
    }

  describe 'without data', ->
    beforeEach ->
      @threshold = new Threshold {is_all_site: true, is_all_condition: true, is_notify: true}

    it 'should default threshold have no conditions', ->
      expect(@threshold.conditions().length).toEqual 0

    it 'should not be valid', ->
      expect(@threshold.valid()).toBeFalsy()

  it 'should check is first condtion', ->
    @threshold.isFirstCondition @threshold.conditions()[0]

  it 'should check is last condtion', ->
    @threshold.isLastCondition @threshold.conditions()[0]

  it 'should add condition', ->
    spyOn(window.model, 'findField').andReturn @field_beds
    @threshold.addNewCondition()
    expect(@threshold.conditions().length).toEqual 2

  it 'should remove condition', ->
    @threshold.removeCondition @threshold.conditions()[0]
    expect(@threshold.conditions().length).toEqual 0

  it "should post set threshold order's json", ->
    spyOn($, 'post')
    callback = (data) ->
    @threshold.setOrder 89, callback
    expect($.post).toHaveBeenCalledWith "/collections/#{@collectionId}/thresholds/#{@threshold.id()}/set_order.json", { ord: 89 }, callback
