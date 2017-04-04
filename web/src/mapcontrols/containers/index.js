import React from 'react';
import { connect } from 'react-redux'

import MapControls from '../components';
import actions from '../actions';

function mapStateToProps(state) {
    return {
        userFilterExpanded: state.userFilters.expanded,
        userFilterEntries: state.userFilters.filtered,
    }
}

function mapActionsToProps(actions) {
    //return _.keyBy(actions, (name, action) => 'on' + _.capitalize(name));
    return {
        onAddUserFilter: actions.addUserFilter,
        onRemoveUserFilter: actions.removeUserFilter,
        onToggleUserFilter: actions.toggleUserFilter,
    };
}

export default connect(mapStateToProps, mapActionsToProps(actions))(MapControls);
