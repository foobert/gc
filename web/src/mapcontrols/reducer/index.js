import update from 'react-addons-update';
import * as ActionTypes from '../actions';

export default function userFilters(state = {filtered: [], expanded: false}, action) {
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
