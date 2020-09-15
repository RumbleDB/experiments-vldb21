
def pytest_addoption(parser):
    parser.addoption(
        '--warehouse_size', action='store', default='XSMALL',
        help='Select warehouse (i.e., cluster) size.')
    parser.addoption(
        '--input_size', action='append', default=[],
        help='Select size (name) of input data set.')

def pytest_generate_tests(metafunc):
    if 'warehouse_size' in metafunc.fixturenames:
        warehouse_size = metafunc.config.option.warehouse_size.upper()
        if warehouse_size not in ['XSMALL', 'SMALL', 'MEDIUM', 'LARGE',
                                  'XLARGE', 'XXLARGE', 'XXXLARGE', 'X4LARGE']:
            raise RuntimeError(
                'Invalid warehouse size: {}'.format(warehouse_size))
        metafunc.parametrize('warehouse_size',
                             [warehouse_size],
                             scope='session')

    if 'input_size' in metafunc.fixturenames:
        input_size = metafunc.config.option.input_size
        input_size = input_size or ['20mb']
        metafunc.parametrize('input_size',
                             input_size,
                             scope='session')
