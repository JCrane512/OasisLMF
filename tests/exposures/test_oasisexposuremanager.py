import csv
import json
import string
from tempfile import NamedTemporaryFile
from unittest import TestCase

import os
from hypothesis import given
from hypothesis.strategies import text, dictionaries, lists, tuples, integers, just
from mock import patch, Mock

from oasislmf.exposures.manager import OasisExposuresManager
from oasislmf.utils.exceptions import OasisException
from ..models.fakes import fake_model


class OasisExposureManagerAddModel(TestCase):
    def test_models_is_empty___model_is_added_to_model_dict(self):
        model = fake_model('supplier', 'model', 'version')

        manager = OasisExposuresManager()
        manager.add_model(model)

        self.assertEqual({model.key: model}, manager.models)

    def test_manager_already_contains_a_model_with_the_given_key___model_is_replaced_in_models_dict(self):
        first = fake_model('supplier', 'model', 'version')
        second = fake_model('supplier', 'model', 'version')

        manager = OasisExposuresManager(oasis_models=[first])
        manager.add_model(second)

        self.assertIs(second, manager.models[second.key])

    def test_manager_already_contains_a_diferent_model___model_is_added_to_dict(self):
        first = fake_model('first', 'model', 'version')
        second = fake_model('second', 'model', 'version')

        manager = OasisExposuresManager(oasis_models=[first])
        manager.add_model(second)

        self.assertEqual({
            first.key: first,
            second.key: second,
        }, manager.models)


class OasisExposureManagerDeleteModels(TestCase):
    def test_models_is_not_in_manager___no_model_is_removed(self):
        manager = OasisExposuresManager([
            fake_model('supplier', 'model', 'version'),
            fake_model('supplier2', 'model2', 'version2'),
        ])
        expected = manager.models

        manager.delete_models([fake_model('supplier3', 'model3', 'version3')])

        self.assertEqual(expected, manager.models)

    def test_models_exist_in_manager___models_are_removed(self):
        models = [
            fake_model('supplier', 'model', 'version'),
            fake_model('supplier2', 'model2', 'version2'),
            fake_model('supplier3', 'model3', 'version3'),
        ]

        manager = OasisExposuresManager(models)
        manager.delete_models(models[1:])

        self.assertEqual({models[0].key: models[0]}, manager.models)


class OasisExposureManagerLoadCanonicalProfile(TestCase):
    def test_model_and_kwargs_are_not_set___result_is_empty_dict(self):
        profile = OasisExposuresManager.load_canonical_profile()

        self.assertEqual({}, profile)

    @given(dictionaries(text(), text()))
    def test_model_is_set_with_profile_json___models_profile_is_set_to_expected_json(self, expected):
        model = fake_model(resources={'canonical_exposures_profile_json': json.dumps(expected)})

        profile = OasisExposuresManager.load_canonical_profile(oasis_model=model)

        self.assertEqual(expected, profile)
        self.assertEqual(expected, model.resources['canonical_exposures_profile'])

    @given(dictionaries(text(), text()), dictionaries(text(), text()))
    def test_model_is_set_with_profile_json_and_profile_json_is_passed_through_kwargs___kwargs_profile_is_used(self, model_profile, kwargs_profile):
        model = fake_model(resources={'canonical_exposures_profile_json': json.dumps(model_profile)})

        profile = OasisExposuresManager.load_canonical_profile(oasis_model=model, canonical_exposures_profile_json=json.dumps(kwargs_profile))

        self.assertEqual(kwargs_profile, profile)
        self.assertEqual(kwargs_profile, model.resources['canonical_exposures_profile'])

    @given(dictionaries(text(), text()))
    def test_model_is_set_with_profile_json_path___models_profile_is_set_to_expected_json(self, expected):
        with NamedTemporaryFile('w') as f:
            json.dump(expected, f)
            f.flush()

            model = fake_model(resources={'canonical_exposures_profile_json_path': f.name})

            profile = OasisExposuresManager.load_canonical_profile(oasis_model=model)

            self.assertEqual(expected, profile)
            self.assertEqual(expected, model.resources['canonical_exposures_profile'])

    @given(dictionaries(text(), text()), dictionaries(text(), text()))
    def test_model_is_set_with_profile_json_path_and_profile_json_path_is_passed_through_kwargs___kwargs_profile_is_used(self, model_profile, kwargs_profile):
        with NamedTemporaryFile('w') as model_file, NamedTemporaryFile('w') as kwargs_file:
            json.dump(model_profile, model_file)
            model_file.flush()
            json.dump(kwargs_profile, kwargs_file)
            kwargs_file.flush()

            model = fake_model(resources={'canonical_exposures_profile_json_path': model_file.name})

            profile = OasisExposuresManager.load_canonical_profile(oasis_model=model, canonical_exposures_profile_json_path=kwargs_file.name)

            self.assertEqual(kwargs_profile, profile)
            self.assertEqual(kwargs_profile, model.resources['canonical_exposures_profile'])


class OasisExposureManagerGetKeys(TestCase):
    def create_model(self, lookup='lookup', keys_file_path='key_file_path', exposures_file_path='exposures_file_path'):
        model = fake_model(resources={'lookup': lookup})
        model.files_pipeline.keys_file_path = keys_file_path
        model.files_pipeline.model_exposures_path = exposures_file_path
        return model

    @given(text(min_size=1, alphabet=string.ascii_letters), text(min_size=1, alphabet=string.ascii_letters), text(min_size=1, alphabet=string.ascii_letters))
    def test_model_is_supplied_kwargs_are_not___lookup_keys_file_and_exposures_file_from_model_are_used(self, lookup, keys, exposure):
        model = self.create_model(lookup=lookup, keys_file_path=keys, exposures_file_path=exposure)

        with patch('oasislmf.exposures.manager.OasisKeysLookupFactory.save_keys', Mock(return_value=(keys, 1))) as oklf_mock:
            res = OasisExposuresManager.get_keys(oasis_model=model)

            oklf_mock.assert_called_once_with(
                lookup=lookup,
                model_exposures_file_path=os.path.abspath(exposure),
                output_file_path=os.path.abspath(keys),
            )
            self.assertEqual(model.files_pipeline.keys_file_path, keys)
            self.assertEqual(res, keys)

    @given(
        text(min_size=1, alphabet=string.ascii_letters), text(min_size=1, alphabet=string.ascii_letters), text(min_size=1, alphabet=string.ascii_letters),
        text(min_size=1, alphabet=string.ascii_letters), text(min_size=1, alphabet=string.ascii_letters), text(min_size=1, alphabet=string.ascii_letters),
    )
    def test_model_and_kwargs_are_supplied___lookup_keys_file_and_exposures_file_from_kwargs_are_used(self, model_lookup, model_keys, model_exposure, lookup, keys, exposure):
        model = self.create_model(lookup=model_lookup, keys_file_path=model_keys, exposures_file_path=model_exposure)

        with patch('oasislmf.exposures.manager.OasisKeysLookupFactory.save_keys', Mock(return_value=(keys, 1))) as oklf_mock:
            res = OasisExposuresManager.get_keys(
                oasis_model=model,
                lookup=lookup,
                model_exposures_file_path=exposure,
                keys_file_path=keys,
            )

            oklf_mock.assert_called_once_with(
                lookup=lookup,
                model_exposures_file_path=os.path.abspath(exposure),
                output_file_path=os.path.abspath(keys),
            )
            self.assertEqual(model.files_pipeline.keys_file_path, keys)
            self.assertEqual(res, keys)


def oasis_keys_data(num_rows):
    return lists(
        tuples(
            integers(min_value=-10, max_value=10),
            just(1),
            integers(min_value=-10, max_value=10),
            integers(min_value=-10, max_value=10),
        ), min_size=num_rows, max_size=num_rows
    ).map(
        lambda l: [(i + 1, ) + row for i, row in enumerate(l)]
    )


def canonical_exposure_data(num_rows, min_value=None, max_value=None):
    return lists(tuples(integers(min_value=min_value, max_value=max_value)), min_size=num_rows, max_size=num_rows).map(
        lambda l: [(i + 1, ) + row for i, row in enumerate(l)]
    )


class OasisExposureManagerGenerateItemsFiles(TestCase):
    @given(text(alphabet=string.ascii_letters, min_size=1), oasis_keys_data(10), canonical_exposure_data(10, min_value=1))
    def test_row_in_keys_data_is_missing_from_exposure_data___oasis_exception_is_raised(self, profile_element_name, keys_data, exposure_data):
        exposure_data.pop()
        profile = {
            profile_element_name: {'ProfileElementName': profile_element_name, 'FieldName': 'TIV', 'CoverageTypeID': 1}
        }

        with NamedTemporaryFile('w') as keys_file, NamedTemporaryFile('w') as exposure_file:
            keys_writer = csv.writer(keys_file)
            keys_writer.writerows(
                [('LocID', 'PerilID', 'CoverageID', 'AreaPerilID', 'VulnerabilityID')] + keys_data
            )
            keys_file.flush()

            exposure_writer = csv.writer(exposure_file)
            exposure_writer.writerows(
                [('ROW_ID', profile_element_name)] + exposure_data
            )
            exposure_file.flush()

            with self.assertRaises(OasisException):
                list(OasisExposuresManager.load_item_records(exposure_file.name, keys_file.name, profile))

    @given(text(alphabet=string.ascii_letters, min_size=1), oasis_keys_data(10), canonical_exposure_data(10, min_value=1))
    def test_row_in_keys_data_is_in_exposure_data_twice___oasis_exception_is_raised(self, profile_element_name, keys_data, exposure_data):
        exposure_data.append(exposure_data[-1])
        profile = {
            profile_element_name: {'ProfileElementName': profile_element_name, 'FieldName': 'TIV', 'CoverageTypeID': 1}
        }

        with NamedTemporaryFile('w') as keys_file, NamedTemporaryFile('w') as exposure_file:
            keys_writer = csv.writer(keys_file)
            keys_writer.writerows(
                [('LocID', 'PerilID', 'CoverageID', 'AreaPerilID', 'VulnerabilityID')] + keys_data
            )
            keys_file.flush()

            exposure_writer = csv.writer(exposure_file)
            exposure_writer.writerows(
                [('ROW_ID', profile_element_name)] + exposure_data
            )
            exposure_file.flush()

            with self.assertRaises(OasisException):
                list(OasisExposuresManager.load_item_records(exposure_file.name, keys_file.name, profile))

    @given(text(alphabet=string.ascii_letters, min_size=1), oasis_keys_data(10), canonical_exposure_data(10, min_value=1))
    def test_each_row_has_a_single_row_per_element_with_each_row_having_a_positive_value_for_the_profile_element___each_row_is_present(self, profile_element_name, keys_data, exposure_data):
        profile = {
            profile_element_name: {'ProfileElementName': profile_element_name, 'FieldName': 'TIV', 'CoverageTypeID': 1}
        }

        expected = []
        for i, zipped_data in enumerate(zip(keys_data, exposure_data)):
            expected.append((
                i + 1,
                zipped_data[0],
                zipped_data[1][1],
            ))

        with NamedTemporaryFile('w') as keys_file, NamedTemporaryFile('w') as exposure_file:
            keys_writer = csv.writer(keys_file)
            keys_writer.writerows(
                [('LocID', 'PerilID', 'CoverageID', 'AreaPerilID', 'VulnerabilityID')] + keys_data
            )
            keys_file.flush()

            exposure_writer = csv.writer(exposure_file)
            exposure_writer.writerows(
                [('ROW_ID', profile_element_name)] + exposure_data
            )
            exposure_file.flush()

            result = list(
                OasisExposuresManager.load_item_records(
                    exposure_file.name,
                    keys_file.name,
                    profile,
                )
            )

        self.assertEqual(len(expected), len(result))
        for expected_row, result_row in zip(expected, result):
            self.assertEqual(expected_row[0], result_row[0])
            self.assertEqual(expected_row[1], tuple(result_row[1]))
            self.assertEqual(expected_row[2], int(result_row[2]))

    @given(text(alphabet=string.ascii_letters, min_size=1), oasis_keys_data(10), canonical_exposure_data(10, min_value=1))
    def test_each_row_has_a_single_row_per_element_with_each_row_having_a_any_value_for_the_profile_element___rows_with_profile_elements_gt_0_are_present(self, profile_element_name, keys_data, exposure_data):
        profile = {
            profile_element_name: {'ProfileElementName': profile_element_name, 'FieldName': 'TIV', 'CoverageTypeID': 1}
        }

        expected = []
        row_id = 0
        for zipped_keys, zipped_exposure in zip(keys_data, exposure_data):
            if zipped_exposure[1] > 0:
                row_id += 1
                expected.append((
                    row_id,
                    zipped_keys,
                    zipped_exposure[1],
                ))

        with NamedTemporaryFile('w') as keys_file, NamedTemporaryFile('w') as exposure_file:
            keys_writer = csv.writer(keys_file)
            keys_writer.writerows(
                [('LocID', 'PerilID', 'CoverageID', 'AreaPerilID', 'VulnerabilityID')] + keys_data
            )
            keys_file.flush()

            exposure_writer = csv.writer(exposure_file)
            exposure_writer.writerows(
                [('ROW_ID', profile_element_name)] + exposure_data
            )
            exposure_file.flush()

            result = list(
                OasisExposuresManager.load_item_records(
                    exposure_file.name,
                    keys_file.name,
                    profile,
                )
            )

        self.assertEqual(len(expected), len(result))
        for expected_row, result_row in zip(expected, result):
            self.assertEqual(expected_row[0], result_row[0])
            self.assertEqual(expected_row[1], tuple(result_row[1]))
            self.assertEqual(expected_row[2], int(result_row[2]))
