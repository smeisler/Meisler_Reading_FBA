# -*- coding: utf-8 -*-
# emacs: -*- mode: python; py-indent-offset: 4; indent-tabs-mode: nil -*-
# vi: set ft=python sts=4 ts=4 sw=4 et:
"""
Base module variables
"""

from ._version import get_versions
__version__ = get_versions()['version']
del get_versions

__author__ = 'The PennLINC Developers'
__copyright__ = 'Copyright 2021, PennLINC, Perelman School of Medicine, University of Pennsylvania'
__credits__ = ['Matt Cieslak', 'Tinashe Tapera', 'Chenying Zhao', 'Valerie Sydnor', 'Josiane Bourque']
__license__ = '3-clause BSD'
__maintainer__ = 'Matt Cieslak'
__status__ = 'Prototype'
__url__ = 'https://github.com/pennlinc/confixel'
__packagename__ = 'confixel'
__description__ = "ConFixel Converts Fixels"
__longdesc__ = """\
A package that converts between
"""

DOWNLOAD_URL = (
    'https://github.com/pennlinc/{name}/archive/{ver}.tar.gz'.format(
        name=__packagename__, ver=__version__))


SETUP_REQUIRES = [
    'setuptools>=18.0',
    'numpy',
    'cython',
]

REQUIRES = [
    'numpy',
    'future',
    'nilearn',
    'nibabel>=2.2.1',
    'pandas',
    'h5py',
    'versioneer'
]

LINKS_REQUIRES = [
]

TESTS_REQUIRES = [
    "mock",
    "codecov",
    "pytest",
]

EXTRA_REQUIRES = {
    'doc': [
        'sphinx>=1.5.3',
        'sphinx_rtd_theme',
        'sphinx-argparse',
        'pydotplus',
        'pydot>=1.2.3',
        'packaging',
        'nbsphinx',
    ],
    'tests': TESTS_REQUIRES,
    'duecredit': ['duecredit'],
    'datalad': ['datalad'],
    'resmon': ['psutil>=5.4.0'],
    # 'sentry': ['raven'],
}
EXTRA_REQUIRES['docs'] = EXTRA_REQUIRES['doc']

# Enable a handle to install all extra dependencies at once
EXTRA_REQUIRES['all'] = list(set([
    v for deps in EXTRA_REQUIRES.values() for v in deps]))

CLASSIFIERS = [
    'Development Status :: 3 - Alpha',
    'Intended Audience :: Science/Research',
    'Topic :: Scientific/Engineering :: Image Recognition',
    'License :: OSI Approved :: BSD License',
    'Programming Language :: Python :: 3.5',
    'Programming Language :: Python :: 3.6',
    'Programming Language :: Python :: 3.7',
]
