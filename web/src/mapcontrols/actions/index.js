export const TOGGLE_USER_FILTER = 'TOGGLE_USER_FILTER';
export function toggleUserFilter() {
    return {
        type: TOGGLE_USER_FILTER,
        payload: {},
    };
}

export const ADD_USER_FILTER = 'ADD_USER_FILTER';
export function addUserFilter(newFilter) {
    return {
        type: ADD_USER_FILTER,
        payload: {
            newFilter,
        },
    };
}

export const REMOVE_USER_FILTER = 'REMOVE_USER_FILTER';
export function removeUserFilter(oldFilter) {
    return {
        type: REMOVE_USER_FILTER,
        payload: {
            oldFilter,
        },
    };
}

export default {
    toggleUserFilter,
    addUserFilter,
    removeUserFilter,
}
