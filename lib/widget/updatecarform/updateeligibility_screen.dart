import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../addcarform/form_button.dart';
import '../addcarform/km_button.dart';
import '../addcarform/text_field.dart';

class UpdateEligibilityScreen extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final Function onNext;
  final Function(String?) onCarRegistrationNumberChanged;
  final Function(String?) onCarBrandChanged;
  final Function(String?) onCarModelChanged;
  final Function(String?) onYearOfRegistrationChanged;
  final Function(String?) onCityChanged;
  final Function(String?) onKmDrivenChanged;
  final Function(String?) onSeatingCapacityChanged;
  final Function(String?) onBodyTypeChanged;
   final String? CarRegistrationNumber;
  final String? carBrand;
  final String? carModel;
  final String? yearOfRegistration;
    final String? city;
  final String? kmDriven;
  final String? seatingCapacity;
  final String? bodyType;
    final bool enabled;

  const UpdateEligibilityScreen({
    super.key,
    required this.formKey,
    required this.onNext,
    required this.onCarRegistrationNumberChanged,
    required this.onCarBrandChanged,
    required this.onCarModelChanged,
    required this.onYearOfRegistrationChanged,
    required this.onCityChanged,
    required this.onKmDrivenChanged,
    required this.kmDriven,
    required this.onSeatingCapacityChanged,
    required this.onBodyTypeChanged,
    required this.seatingCapacity,
    required this.bodyType,
      this.CarRegistrationNumber,
    this.city,
    this.carBrand,
    this.carModel,
      this.yearOfRegistration,
     this.enabled = true,
  });

  @override
  UpdateEligibilityScreenState createState() => UpdateEligibilityScreenState();
}

class UpdateEligibilityScreenState extends State<UpdateEligibilityScreen> {
  String? _selectedKm;
  String? _selectedSeatingCapacity;
  String? _selectedBodyType;
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
    final TextEditingController _yearController = TextEditingController();
     final TextEditingController _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
      _selectedKm = widget.kmDriven;
     _selectedSeatingCapacity = widget.seatingCapacity;
      _selectedBodyType = widget.bodyType;
     _licenseController.text = widget.CarRegistrationNumber ?? '';
     _brandController.text = widget.carBrand ?? '';
       _modelController.text = widget.carModel ?? '';
      _yearController.text = widget.yearOfRegistration ?? '';
        _cityController.text = widget.city ?? '';

  }

  @override
  void dispose() {
      _licenseController.dispose();
        _brandController.dispose();
        _modelController.dispose();
        _yearController.dispose();
      _cityController.dispose();
    super.dispose();
  }
  bool _isValidLicenseNumber(String value) {
    if (value.length != 10) return false;

    for (int i = 0; i < value.length; i++) {
      final char = value[i];
      if (i < 2 || (i >= 4 && i < 6)) {
        if (!RegExp(r'[A-Z]').hasMatch(char.toUpperCase())) return false;
      } else if (i >= 2 && i < 4 || i >= 6) {
        if (!RegExp(r'[0-9]').hasMatch(char)) return false;
      }
    }
    return true;
  }

  String _formatLicenseNumber(String value) {
    String formatted = '';
    for (int i = 0; i < value.length; i++) {
      if (i < 2 || (i >= 4 && i < 6)) {
        formatted += value[i].toUpperCase();
      } else {
        formatted += value[i];
      }
    }
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: widget.formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Checking car eligibility',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
               TextFormField(
                   controller: _licenseController,
                  maxLength: 10,
                    enabled:false,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Car Registration Number',
                    border: OutlineInputBorder(),
                  ),
                    onChanged: (value) {
                    setState(() {
                      _licenseController.value =
                          _licenseController.value.copyWith(
                        text: _formatLicenseNumber(value),
                        selection: TextSelection.collapsed(
                            offset: _formatLicenseNumber(value).length),
                      );
                    });
                    widget.onCarRegistrationNumberChanged(value);
                  },
                   onSaved: (value) =>
                      widget.onCarRegistrationNumberChanged(value),
                    validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter Car Registration Number';
                    }
                    if (!_isValidLicenseNumber(value)) {
                      return 'Please enter valid car registration number';
                    }
                    return null;
                  },
                 ),
              SizedBox(height: screenHeight * 0.02),
                  TextFormField(
                      controller: _brandController,
                    enabled:false,
                  decoration: const InputDecoration(
                    labelText: 'Car Brand',
                    border: OutlineInputBorder(),
                  ),
                    onChanged: (value) {
                    setState(() {
                      _brandController.value = _brandController.value.copyWith(
                        text: value.toUpperCase(),
                        selection: TextSelection.collapsed(
                            offset: value.toUpperCase().length),
                      );
                    });
                    widget.onCarBrandChanged(value);
                  },
                   onSaved: (value) => widget.onCarBrandChanged(value),
                 validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter car brand';
                    }
                    return null;
                  }),
                SizedBox(height: screenHeight * 0.02),
                 TextFormField(
                   controller: _modelController,
                    enabled:false,
                decoration: const InputDecoration(
                  labelText: 'Car Model',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _modelController.value = _modelController.value.copyWith(
                      text: value.toUpperCase(),
                      selection: TextSelection.collapsed(
                          offset: value.toUpperCase().length),
                    );
                  });
                   widget.onCarModelChanged(value);
                },
                onSaved: (value) => widget.onCarModelChanged(value),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter car model';
                  }
                  return null;
                },
              ),
              SizedBox(height: screenHeight * 0.02),
              CustomTextField(
                controller: _yearController,
                  enabled: false,
                label: 'Year of registration',
                onSaved: (value) => widget.onYearOfRegistrationChanged(value),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter year of registration';
                  }
                  if (value.length != 4 || int.tryParse(value) == null) {
                    return 'Enter valid year';
                  }
                  return null;
                },
                 onChanged: (value){},
              ),
               SizedBox(height: screenHeight * 0.02),
                TextFormField(
                 controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _cityController.value = _cityController.value.copyWith(
                        text: value.toUpperCase(),
                        selection: TextSelection.collapsed(
                            offset: value.toUpperCase().length),
                      );
                    });
                   widget.onCityChanged(value);
                  },
                   onSaved: (value) => widget.onCityChanged(value),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter city';
                    }
                    return null;
                  },
              ),
                 SizedBox(height: screenHeight * 0.02),
                const Text(
                  'Car Seating Capacity',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
               Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedSeatingCapacity == '2'
                              ? Colors.blue
                              : Colors.white,
                          foregroundColor: _selectedSeatingCapacity == '2'
                              ? Colors.white
                              : Colors.black,
                          side: const BorderSide(color: Colors.grey),
                        ),
                         child: const Text('2'),
                      ),
                    ),
                   Expanded(
                      child: ElevatedButton(
                       onPressed: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedSeatingCapacity == '4'
                              ? Colors.blue
                              : Colors.white,
                          foregroundColor: _selectedSeatingCapacity == '4'
                              ? Colors.white
                              : Colors.black,
                          side: const BorderSide(color: Colors.grey),
                        ),
                        child: const Text('4'),
                      ),
                    ),
                     Expanded(
                      child: ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedSeatingCapacity == '5'
                              ? Colors.blue
                              : Colors.white,
                          foregroundColor: _selectedSeatingCapacity == '5'
                              ? Colors.white
                              : Colors.black,
                          side: const BorderSide(color: Colors.grey),
                        ),
                        child: const Text('5'),
                      ),
                    ),
                   Expanded(
                      child: ElevatedButton(
                          onPressed: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedSeatingCapacity == '7'
                              ? Colors.blue
                              : Colors.white,
                          foregroundColor: _selectedSeatingCapacity == '7'
                              ? Colors.white
                              : Colors.black,
                          side: const BorderSide(color: Colors.grey),
                        ),
                        child: const Text('7'),
                      ),
                    ),
                  ],
                ),
                  SizedBox(height: screenHeight * 0.02),
                  const Text(
                    'Body Type',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  DropdownButtonFormField<String>(
                    value: _selectedBodyType,
                    items: <String>[
                      'Sedan',
                      'Hatchback',
                      'SUV',
                      'Minivan',
                      'Convertible',
                      'Coupe',
                      'Wagon',
                      'Van'
                    ].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                      onChanged: null,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select Body type';
                    }
                    return null;
                  },
                  ),
                  SizedBox(height: screenHeight * 0.02),
                    const Text(
                    'Car KM Driven',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: KMButton(
                          label: '0-20k',
                          onPressed: () {
                            setState(() {
                              _selectedKm = '0-20k';
                            });
                              widget.onKmDrivenChanged('0-20k');
                          },
                          isSelected: _selectedKm == '0-20k',
                          value: '0-20k',
                        ),
                      ),
                      Expanded(
                        child: KMButton(
                          label: '20-40k',
                           onPressed: () {
                            setState(() {
                              _selectedKm = '20-40k';
                            });
                             widget.onKmDrivenChanged('20-40k');
                          },
                          isSelected: _selectedKm == '20-40k',
                          value: '20-40k',
                        ),
                      ),
                       Expanded(
                        child: KMButton(
                          label: '40-60k',
                            onPressed: () {
                            setState(() {
                              _selectedKm = '40-60k';
                            });
                               widget.onKmDrivenChanged('40-60k');
                          },
                          isSelected: _selectedKm == '40-60k',
                          value: '40-60k',
                        ),
                      ),
                    ],
                  ),
                   SizedBox(height: screenHeight * 0.01),
                   Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: KMButton(
                          label: '>60k',
                            onPressed: () {
                            setState(() {
                              _selectedKm = '>60k';
                            });
                              widget.onKmDrivenChanged('>60k');
                          },
                          isSelected: _selectedKm == '>60k',
                          value: '>60k',
                        ),
                      ),
                    ],
                  ),
              SizedBox(height: screenHeight * 0.04),
               SizedBox(
                width: double.infinity,
                child: FormButton(
                  onPressed: () {
                    if (widget.formKey.currentState!.validate()) {
                      if (_selectedSeatingCapacity == null) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                          content: Text('Please select Car Seating Capacity'),
                        ));
                        return;
                      }
                         if (_selectedKm == null) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                          content: Text('Please select KM Driven'),
                        ));
                        return;
                      }
                       widget.formKey.currentState!.save();
                      widget.onNext();
                    }
                  },
                  label: 'Next',
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}