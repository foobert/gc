import * as ActionTypes from '../actions'
import { routeReducer } from 'react-router-redux'
import { combineReducers } from 'redux'
import update from 'react-addons-update'

function notifications(state = {callouts: []}, action) {
    switch (action.type) {

        case ActionTypes.CREATE_CALLOUT:
            return update(state, {callouts: {$push: [action.payload]}})

        case ActionTypes.REMOVE_CALLOUT:
            const { id } = action.payload
            const index = state.callouts.map(item => item.id).indexOf(id)
            return update(state, {callouts: {$splice: [[index, 1]]}})

        default:
            return state
    }
}

function userFilters(state = {filtered: [], expanded: false}, action) {
    switch (action.type) {
        case ActionTypes.TOGGLE_USER_FILTER:
            return update(state, {expanded: {$apply: (x) => !x}});
        case ActionTypes.ADD_USER_FILTER:
            if (action.payload.newFilter.length === 0 || state.filtered.indexOf(action.payload.newFilter) > -1) {
                return state;
            }
            return update(state, {filtered: {$push: [action.payload.newFilter]}});
        case ActionTypes.REMOVE_USER_FILTER:
            return update(state, {filtered: {$splice: [[state.filtered.indexOf(action.payload.oldFilter), 1]]}});
        default:
            return state;
    }
}

const rootReducer = combineReducers({
    routing: routeReducer,
    notifications,
    userFilters,
})

export default rootReducer
