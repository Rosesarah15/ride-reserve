import 'package:ayinza_commons/utils/validatable_form.dart';

class DestinationForm extends ValidatableForm {
  DestinationForm._();

  static final DestinationForm _instance = DestinationForm._();

  static DestinationForm get instance => _instance;
}