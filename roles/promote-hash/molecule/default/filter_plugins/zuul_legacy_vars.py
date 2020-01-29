#!/usr/bin/python
class FilterModule(object):
    def filters(self):
        return {
            'zuul_legacy_vars': self.zuul_legacy_vars
        }

    def zuul_legacy_vars(self, env_var):
        #fake filter for molecule
        return env_var
